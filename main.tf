data "aws_caller_identity" "this" {}
data "aws_region" "current" {}

terraform {
  required_version = ">= 0.12"
}

variable "inventory_map" {
  type    = map(string)
  default = {}
}

// Order of precedence is inventory_file > inventory_yaml > ips > ip
locals {
  //  inventory_ip = var.ip == "" ? "" : "${var.ip},"
  //  inventory_ips = var.ips == null ? "" : "%{for ip in var.ips}${ip},%{ endfor }"
  //  inventory_ips_combined = "'${local.inventory_ips}${local.inventory_ip}'"
  //  inventory = var.inventory_file != "" ? var.inventory_file :
  //              var.inventory_template != "" ? local_file.inventory_template.*.filename[0] :
  //              var.ips != null ? "%{for ip in var.ips}${ip},%{ endfor }" :
  //              var.ip != "" ? "${var.ip}," : ""

  inventory = var.inventory_file != "" ? var.inventory_file : var.inventory_template != "" ? local_file.inventory_template.*.filename[0] : var.ips != null ? "%{for ip in var.ips}${ip},%{endfor}" : var.ip != "" ? "${var.ip}," : ""
}

resource "null_resource" "requirements" {
  count = var.requirements_file_path == "" ? 0 : 1

  triggers = {
    apply_time = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
ansible-galaxy install -r ${var.requirements_file_path}
EOT
  }
}

resource "local_file" "inventory_template" {
  count    = var.inventory_template == "" ? 0 : 1
  content  = template_file.inventory_template.*.rendered[0]
  filename = "${path.module}/ansible_inventory"

  depends_on = [template_file.inventory_template, null_resource.requirements]
}

resource "template_file" "inventory_template" {
  count    = var.inventory_template == "" ? 0 : 1
  template = file(var.inventory_template)
  vars     = var.inventory_template_vars
}

resource "template_file" "ssh_cfg" {

  template = <<-EOF
%{for cidr in var.cidr_block_matches}
Host ${cidr}
  ProxyCommand    ssh -A -W %h:%p ${var.bastion_user}@${var.bastion_ip} -F ${path.module}/ssh.cfg
  IdentityFile    ${var.private_key_path}
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
%{endfor}

Host ${var.bastion_ip}
  Hostname ${var.bastion_ip}
  User ${var.bastion_user}
  IdentitiesOnly yes
  IdentityFile ${var.private_key_path}
  ControlMaster auto
  ControlPath ~/.ssh/ansible-%r@%h:%p
  ControlPersist 5m
  StrictHostKeyChecking=no
  UserKnownHostsFile=/dev/null
EOF
}

resource "template_file" "ansible_cfg" {
  //  ssh_args = -F ./ssh.cfg
  template = <<-EOF
[ssh_connection]
ssh_args = -C -F ${path.module}/ssh.cfg
EOF
}

resource "template_file" "ansible_sh" {
  template = <<-EOT
%{if var.bastion_ip != ""}
while ! nc -vz ${var.bastion_ip} 22; do
  sleep 1
done
%{endif}
ANSIBLE_SCP_IF_SSH=true
ANSIBLE_FORCE_COLOR=true
export ANSIBLE_SSH_RETRIES=10
export ANSIBLE_HOST_KEY_CHECKING=False
%{if var.roles_dir != ""}ANSIBLE_ROLES_PATH='${var.roles_dir}'%{endif}
%{if var.bastion_ip != ""}export ANSIBLE_CONFIG='${path.module}/ansible.cfg'%{endif}
ansible-playbook '${var.playbook_file_path}' \
--inventory=${local.inventory} \
--user=${var.user} \
--become-method='sudo' \
--become-user='root' \
--become \
--forks=5 \
--ssh-extra-args='-p 22 -o ConnectTimeout=10 -o ConnectionAttempts=10 -o StrictHostKeyChecking=no -o IdentitiesOnly=yes' \
%{if var.verbose}-vvvv %{endif}\
--private-key='${var.private_key_path}' %{if var.playbook_vars != {} }\
--extra-vars='${jsonencode(var.playbook_vars)}'%{endif} %{if var.playbook_vars_file != "" }\
--extra-vars=@${var.playbook_vars_file}%{endif}
EOT
}

//--ssh-extra-args='-p 22 -o StrictHostKeyChecking=no' \
//-o ConnectTimeout=60 -o ConnectionAttempts=10
//%{ if var.verbose }
//-vvvv \ %{ endif }

resource "local_file" "ssh_cfg" {
  content  = template_file.ssh_cfg.rendered
  filename = "${path.module}/ssh.cfg"
}

resource "local_file" "ansible_cfg" {
  content  = template_file.ansible_cfg.rendered
  filename = "${path.module}/ansible.cfg"
}

resource "local_file" "ansible_sh" {
  content         = template_file.ansible_sh.rendered
  filename        = "${path.module}/ansible.sh"
  file_permission = "0755"
}

resource "null_resource" "ansible_run" {
  triggers = {
    apply_time = timestamp()
  }

  provisioner "local-exec" {
    command = "${path.module}/ansible.sh"
  }

  depends_on = [local_file.ansible_sh, local_file.ansible_cfg, local_file.ssh_cfg]
}

resource "null_resource" "cleanup" {
  count = var.cleanup ? 1 : 0
  triggers = {
    apply_time = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
%{if var.bastion_ip != ""}
rm -f ${path.module}/ssh.cfg
rm -f ${path.module}/ansible.cfg
%{endif}
rm -f ${path.module}/ansible.sh
EOT
  }

  depends_on = [null_resource.ansible_run]
}
