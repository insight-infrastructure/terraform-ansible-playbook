variable "name" {
  type = string
  default = "node-configuration"
}

variable "user" {
  type = string
  description = "The user used to configure the node"
  default = "Ubuntu"
}

variable "private_key_path" {
  type = string
  description = "SSH Private Key of to configure the node"
  default = ""
}

variable "playbook_file_path" {
  type = string
  description = "Absolute path to playbook file to configure the node"
  default = ""
}

variable "roles_dir" {
  type = string
  description = "Absolute path to roles directory to configure the node"
  default = ""
}

variable "ip" {
  type = string
  description = "The elastic ip address of the node being configured."
  default = ""
}

variable "cidr_block_matches" {
  type = list(string)
  default = ["10.*.*.*", "17.??.*.*", "192.168.*.*"]
}

variable "bastion_user" {
  type = string
  default = ""
}

variable "bastion_ip" {
  type = string
  default = ""
}

variable "playbook_vars" {
  type = map(string)
  default = {}
  description = "Extra vars to include in run"
}

