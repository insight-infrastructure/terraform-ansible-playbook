variable "private_key_path" {
  type = string
}

variable "public_key_path" {
  type = string
}

variable "user" {
  type = string
}

variable "instance_name" {
  default = "stuff-n-things"
}

variable "playbook_file_path" {
  type = string
}
