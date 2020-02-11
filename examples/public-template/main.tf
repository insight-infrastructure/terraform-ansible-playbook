resource "random_pet" "this" {
  length = 2
}

resource "aws_security_group" "this" {
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "this" {
  key_name   = random_pet.this.id
  public_key = file(var.public_key_path)
}

resource "aws_instance" "this" {
  count                  = 3
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.this.id]

  key_name                    = aws_key_pair.this.key_name
  associate_public_ip_address = true
}

module "ansible" {
  source = "../../"

  inventory_template = var.inventory_template
  //  inventory_template = "${path.cwd}/ansible_inventory_1.tpl"

  inventory_template_vars = {
    host_ip_1       = aws_instance.this.*.public_ip[0]
    hostname_1      = "foo"
    hostname_1_vars = <<-EOT
    stuff = "things"
EOT

    hostname_2 = "bar"
    host_ip_2  = aws_instance.this.*.public_ip[1]
    hostname_3 = "baz"
    host_ip_3  = aws_instance.this.*.public_ip[2]
  }

  playbook_file_path = var.playbook_file_path
  user               = "ubuntu"
  private_key_path   = var.private_key_path
}