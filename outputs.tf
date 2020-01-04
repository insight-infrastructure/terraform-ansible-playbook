output "status" {
  value = "Node Configured! - ${null_resource.ansible_run.id}"
}

output "ip" {
  value = var.ip
}
