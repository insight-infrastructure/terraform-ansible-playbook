terraform {
  required_version = ">= 0.12"
}


locals {
  // Order of precedence is inventory_file > inventory_yaml > ips > ip
  inventory = var.inventory_file != "" ? var.inventory_file : var.inventory_template != "" ? "${path.module}/ansible_inventory" : var.ips != null ? "%{for ip in var.ips}${ip},%{endfor}" : var.ip != "" ? "${var.ip}," : ""

  playbook = var.playbook_template_path == "" ? var.playbook_file_path : "${path.module}/playbook_template.yml"
}

resource "null_resource" "requirements" {
  count = var.requirements_file_path == "" || ! var.create ? 0 : 1

  provisioner "local-exec" {
    when = create
    command = <<-EOT
ansible-galaxy install -r ${var.requirements_file_path}
EOT
  }
}

//resource "local_file" "inventory_template" {
//  count    = var.inventory_template == "" ? 0 : 1
//  content  = template_file.inventory_template.*.rendered[0]
//  filename = "${path.module}/ansible_inventory"
//}

resource "null_resource" "inventory_template" {
  count = var.inventory_template == "" ? 0 : 1

  provisioner "local-exec" {
    when = create
    command = <<-EOT
cat<<EOF > ${path.module}/ansible_inventory
${templatefile(var.inventory_template, var.inventory_template_vars)}
EOF
EOT
  }
}

resource "null_resource" "playbook_template" {
  count = var.playbook_template_path == "" ? 0 : 1

  provisioner "local-exec" {
    when = create
    command = <<-EOT
cat<<EOF > ${path.module}/playbook_template.yml
${templatefile(var.playbook_template_path, var.playbook_template_vars)}
EOF
EOT
  }
}

//resource "template_file" "inventory_template" {
//  count    = var.inventory_template == "" ? 0 : 1
//  template = file(var.inventory_template)
//  vars     = var.inventory_template_vars
//}

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
ansible-playbook '${local.playbook}' \
--inventory=${local.inventory} \
--user=${var.user} \
%{if var.ask_vault_pass}--ask-vault-pass %{endif}\
%{if var.become}--become-method='${var.become_method}' %{endif}\
%{if var.become}--become-user='${var.become_user}' %{endif}\
%{if var.become}--become %{endif}\
%{if var.flush_cache}--flush-cache %{endif}\
%{if var.force_handlers}--force-handlers %{endif}\
%{if var.scp_extra_args != ""}--scp-extra-args='${var.scp_extra_args}' %{endif}\
%{if var.sftp_extra_args != ""}--sftp-extra-args='${var.sftp_extra_args}' %{endif}\
%{if var.skip_tags != ""}--skip-tags='${var.skip_tags}' %{endif}\
%{if var.ssh_common_args != ""}--ssh-common-args='${var.ssh_common_args}' %{endif}\
%{if var.ssh_extra_args != ""}--ssh-extra-args='${var.ssh_extra_args}' %{endif}\
%{if var.start_at_task != ""}--start-at-task='${var.start_at_task}' %{endif}\
%{if var.step}--step %{endif}\
%{if var.vault_id != ""}--vault-id %{endif}\
%{if var.vault_password_file != ""}--vault-password-file='${var.vault_password_file}' %{endif}\
--forks=${var.forks} \
%{if var.verbose}-vvvv %{endif}\
--private-key='${var.private_key_path}'\
%{if var.playbook_vars != {} }--extra-vars='${jsonencode(var.playbook_vars)}'%{endif} \
%{if var.playbook_vars_file != ""}--extra-vars=@${var.playbook_vars_file}%{endif}
EOT
}

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
  count = var.create ? 1 : 0

  provisioner "local-exec" {
    when = create
    command = "${path.module}/ansible.sh"
  }

  depends_on = [local_file.ansible_sh, local_file.ansible_cfg, local_file.ssh_cfg, null_resource.requirements, null_resource.inventory_template]
}

resource "null_resource" "cleanup" {
  count = var.cleanup && var.create ? 1 : 0

  provisioner "local-exec" {
    when = create
    command = <<-EOT
%{if var.bastion_ip != ""}
rm -f ${path.module}/ssh.cfg
rm -f ${path.module}/ansible.cfg
%{endif}
%{if var.playbook_template_path != ""}
rm -f ${path.module}/playbook_template.yml
%{endif}
rm -f ${path.module}/ansible.sh
EOT
  }

  depends_on = [null_resource.ansible_run]
}
