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
    "Terraform"   = true
    "Environment" = var.environment
  }

  tags = merge(var.tags, local.common_tags)
}

resource "null_resource" "this" {
  triggers = {
    apply_time = timestamp()
  }

  provisioner "local-exec" {
    command = "ANSIBLE_SCP_IF_SSH=true ANSIBLE_FORCE_COLOR=true ANSIBLE_ROLES_PATH='${local.playbook_roles}' ansible-playbook '${local.playbook_file}' --inventory='${local.eip},' --become --become-method='sudo' --become-user='root' --forks=5 --user='${local.user}' --private-key='${local.private_key}' --ssh-extra-args='-p 22 -o ConnectTimeout=10 -o ConnectionAttempts=10 -o StrictHostKeyChecking=no'"
  }
}
