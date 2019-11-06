data "aws_caller_identity" "this" {}
data "aws_region" "current" {}

terraform {
  required_version = ">= 0.12"
}

locals {
  name = var.name
  eip = var.eip
  user = var.config_user
  private_key = var.config_private_key
  playbook_file = var.config_playbook_file
  playbook_roles = var.config_playbook_roles_dir
  common_tags = {
    "Name" = local.name
    "Terraform" = true
  }

  tags = merge(var.tags, local.common_tags)
}

data "template_file" "ssh_cfg" {

  template = <<-EOF
%{ for cidr in var.cidr_block_matches }
Host ${cidr}
  ProxyCommand    ssh -A -W %h:%p ubuntu@${var.bastion_dns}
  IdentityFile    ${var.config_private_key}
%{ endfor }

Host ${var.bastion_dns}
  Hostname ${var.bastion_dns}
  User ${var.bastion_user}
  IdentityFile ${var.config_private_key}
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
    appply_time = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
%{ if var.bastion_dns != "" }
echo '${data.template_file.ssh_cfg.rendered}' >> ${path.module}/ssh.cfg
echo '${data.template_file.ansible_cfg.rendered}' >> ${path.module}/ansible.cfg
%{ endif }
echo '${data.template_file.ansible_sh.rendered}' >> ${path.module}/ansible.sh
EOT
  }
}

data "template_file" "ansible_sh" {
  template = <<-EOT
ANSIBLE_SCP_IF_SSH=true
ANSIBLE_FORCE_COLOR=true
ANSIBLE_ROLES_PATH='${local.playbook_roles}'
%{ if var.bastion_dns != "" }
ANSIBLE_CONFIG=${path.module}/ansible.cfg
ansible-playbook '${local.playbook_file}' \
--inventory='${local.eip},' \
--user=${local.user} \
--become-method=sudo \
--become \
--forks=5 \
--ssh-extra-args='-p 22 -o ConnectTimeout=10 -o ConnectionAttempts=10 -o StrictHostKeyChecking=no' \
--private-key='${local.private_key}' %{ if var.playbook_vars != {} }\
--extra-vars='${jsonencode(var.playbook_vars)}'
%{ endif }
  %{ else }
ansible-playbook '${local.playbook_file}' \
--inventory='${local.eip},' \
--become \
--become-method='sudo' \
--become-user='root' \
--forks=5 \
--user='${local.user}' \
--private-key='${local.private_key}' \
--ssh-extra-args="'-p 22 -o ConnectTimeout=10 -o ConnectionAttempts=10 -o StrictHostKeyChecking=no'"  %{ if var.playbook_vars != {} }\
--extra-vars='${jsonencode(var.playbook_vars)}'
%{ endif }
%{ endif }
EOT
}

resource "null_resource" "this" {
  triggers = {
    apply_time = timestamp()
  }

  provisioner "local-exec" {
    command = data.template_file.ansible_sh.rendered
  }

  depends_on = [null_resource.write_cfg]
}


//resource "null_resource" "this" {
//  triggers = {
//    apply_time = timestamp()
//  }
//
//  provisioner "local-exec" {
//    command = "ANSIBLE_SCP_IF_SSH=true ANSIBLE_FORCE_COLOR=true ANSIBLE_ROLES_PATH='${local.playbook_roles}' ansible-playbook '${local.playbook_file}' --inventory='${local.eip},' --become --become-method='sudo' --become-user='root' --forks=5 --user='${local.user}' --private-key='${local.private_key}' --ssh-extra-args='-p 22 -o ConnectTimeout=10 -o ConnectionAttempts=10 -o StrictHostKeyChecking=no'"
//  }
//
//  provisioner "local-exec" {
//    command = <<-EOF
//  ANSIBLE_SCP_IF_SSH=true \
//  ANSIBLE_FORCE_COLOR=true \
//  ANSIBLE_ROLES_PATH='${local.playbook_roles}' \
//  ansible-playbook '${local.playbook_file}' \
//  --inventory='${local.eip},' \
//  --become --become-method='sudo' --become-user='root' --forks=5 --user='${local.user}' --private-key='${local.private_key}' --ssh-extra-args='-p 22 -o ConnectTimeout=10 -o ConnectionAttempts=10 -o StrictHostKeyChecking=no'
//
//  EOF
//  }
//
//}
