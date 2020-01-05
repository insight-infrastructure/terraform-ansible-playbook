data "aws_caller_identity" "this" {}
data "aws_region" "current" {}

terraform {
  required_version = ">= 0.12"
}

resource "template_file" "ssh_cfg" {

  template = <<-EOF
%{ for cidr in var.cidr_block_matches }
Host ${cidr}
  ProxyCommand    ssh -A -W %h:%p ubuntu@${var.bastion_ip}
  IdentityFile    ${var.private_key_path}
%{ endfor }

Host ${var.bastion_ip}
  Hostname ${var.bastion_ip}
  User ${var.bastion_user}
  IdentityFile ${var.private_key_path}
  ControlMaster auto
  ControlPath ~/.ssh/ansible-%r@%h:%p
  ControlPersist 5m
  StrictHostKeyChecking=no
  UserKnownHostsFile=/dev/null
EOF
}

data "template_file" "ansible_cfg" {
  template = <<-EOF
[ssh_connection]
ssh_args = -F ./ssh.cfg
control_path = ~/.ssh/mux-%r@%h:%p
EOF
}

data "template_file" "ansible_vars" {
  template = <<-EOF
keys
EOF
}

resource "null_resource" "write_cfg" {
  triggers = {
    ip = var.ip
    sh_template = template_file.ansible_sh.rendered
    cfg_template = data.template_file.ansible_cfg.rendered
    ssh_template = template_file.ssh_cfg.rendered
  }

  provisioner "local-exec" {
    command = <<-EOT
%{ if var.bastion_ip != "" }
echo '${template_file.ssh_cfg.rendered}' > ${path.module}/ssh.cfg
echo '${data.template_file.ansible_cfg.rendered}' > ${path.module}/ansible.cfg
%{ endif }
echo '${template_file.ansible_sh.rendered}' > ${path.module}/ansible.sh
EOT
  }
//  Don't need to write ansible.sh but nice for debugging
}

resource "template_file" "ansible_sh" {
  template = <<-EOT
ANSIBLE_SCP_IF_SSH=true
ANSIBLE_FORCE_COLOR=true
ANSIBLE_ROLES_PATH='${var.roles_dir}'
%{ if var.bastion_ip != "" }
ANSIBLE_CONFIG=${path.module}/ansible.cfg
ansible-playbook '${var.playbook_file_path}' \
--inventory='${var.ip},' \
--user=${var.user} \
--become-method=sudo \
--become \
--forks=5 \
--ssh-extra-args='-p 22 -o ConnectTimeout=10 -o ConnectionAttempts=10 -o StrictHostKeyChecking=no' \
--private-key='${var.private_key_path}' %{ if var.playbook_vars != {} }\
--extra-vars='${jsonencode(var.playbook_vars)}'
%{ endif }
  %{ else }
ansible-playbook '${var.playbook_file_path}' \
--inventory='${var.ip},' \
--become \
--become-method='sudo' \
--become-user='root' \
--forks=5 \
--user='${var.user}' \
--private-key='${var.private_key_path}' \
--ssh-extra-args='-p 22 -o ConnectTimeout=10 -o ConnectionAttempts=10 -o StrictHostKeyChecking=no'  %{ if var.playbook_vars != {} }\
--extra-vars='${jsonencode(var.playbook_vars)}'
%{ endif }
%{ endif }
EOT
}

resource "null_resource" "ansible_run" {
  triggers = {
    apply_time = timestamp()
  }

  provisioner "local-exec" {
    command = template_file.ansible_sh.rendered
  }

  depends_on = [null_resource.write_cfg]
}