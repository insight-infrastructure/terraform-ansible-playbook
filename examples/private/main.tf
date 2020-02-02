
resource "random_pet" "this" {
  length = 2
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a"]
  private_subnets = ["10.0.1.0/24"]
  public_subnets  = ["10.0.101.0/24"]

  enable_nat_gateway = false

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

resource "aws_key_pair" "this" {
  key_name = random_pet.this.id
  public_key = file(var.public_key_path)
}

resource "aws_instance" "bastion" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  subnet_id = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.this.id]

  associate_public_ip_address = true
  key_name = aws_key_pair.this.key_name

  tags = {
    Name = "bastion-${random_pet.this.id}"
  }
}

resource "aws_security_group" "this" {
  vpc_id = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    # To keep this example simple, we allow incoming SSH requests from any IP. In real-world usage, you should only
    # allow SSH requests from trusted servers, such as a bastion host or VPN server.
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "this" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  subnet_id = module.vpc.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.this.id]

  key_name = aws_key_pair.this.key_name

  tags = {
    Name = "bastion-${random_pet.this.id}"
  }
}

module "ansible" {
  source = "../../"
  ip = aws_instance.this.public_ip
  playbook_file_path = var.playbook_file_path
  roles_dir = "../ansible/roles"

  bastion_ip = aws_instance.bastion.public_ip
  bastion_user = "ubuntu"

  user = var.user
  private_key_path = var.private_key_path
}

