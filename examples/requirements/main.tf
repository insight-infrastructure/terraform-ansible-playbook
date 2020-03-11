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
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.this.id]

  key_name                    = aws_key_pair.this.key_name
  associate_public_ip_address = true
}

module "ansible" {
  source = "../../"

  create = var.create

  ip                 = aws_instance.this.public_ip
  playbook_file_path = var.playbook_file_path
  roles_dir          = "../ansible/roles"
  user               = "ubuntu"
  private_key_path   = var.private_key_path

  requirements_file_path = "${path.cwd}/requirements_dev.yml"
}

