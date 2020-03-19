output "image_id" {
  value = data.aws_ami.ubuntu.id
}

output "public_ip" {
  value = aws_instance.this.public_ip
}
