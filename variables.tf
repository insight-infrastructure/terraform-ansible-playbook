variable "name" {
  type = string
  default = "node-configuration"
}

variable "environment" {
  description = "The environment that generally corresponds to the account you are deploying into."
}

variable "config_user" {
  type = string
  description = "The user used to configure the node"
}

variable "config_private_key" {
  type = string
  description = "SSH Private Key of to configure the node"
}

variable "config_playbook_file" {
  type = string
  description = "Absolute path to playbook file to configure the node"
}

variable "config_playbook_roles_dir" {
  type = string
  description = "Absolute path to roles directory to configure the node"
}

variable "eip" {
  description = "The elastic ip address of the node being configured."
}

variable "tags" {
  description = "Tags that are appended"
  type = map(string)
}
