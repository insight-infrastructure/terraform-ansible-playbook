###################
# Playbook Env Vars
###################
variable "private_key_path" {
  type        = string
  description = "Path to SSH private key to configure the node"
}

variable "playbook_file_path" {
  type        = string
  description = "Absolute path to playbook file to configure the node"
}

variable "roles_dir" {
  type        = string
  description = "Absolute path to roles directory to configure the node"
  default     = ""
}

#################
# Inventory Items
#################
variable "ip" {
  description = "The elastic ip address of the node being configured."
  default     = ""
}

variable "ips" {
  type    = list(string)
  default = null
}

variable "inventory" {
  type    = map(string)
  default = {}
}

variable "inventory_file" {
  type    = string
  default = ""
}

variable "inventory_template" {
  type    = string
  default = ""
}

variable "inventory_template_vars" {
  //  type = list(map(string))
  type    = map(string)
  default = {}
}

############
# ssh Config
############
variable "cidr_block_matches" {
  type    = list(string)
  default = ["10.*.*.*", "17.??.*.*", "192.168.*.*"]
}

variable "bastion_user" {
  type    = string
  default = ""
}

variable "bastion_ip" {
  type    = string
  default = ""
}

###############
# Playbook Args
###############
variable "user" {
  type        = string
  description = "The user used to configure the node"
}

variable "verbose" {
  type    = bool
  default = false
}

variable "playbook_vars" {
  type        = map(string)
  default     = {}
  description = "Extra vars to include in run"
}

#######
# Other
#######
variable "cleanup" {
  type    = bool
  default = false
}