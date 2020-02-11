# terraform-aws-icon-node-configuration

Terraform module for running ansible playbooks. Supports running over bastion host. Inventory can be supplied with
variables in the following order of precedence:
- inventory_file - path to inventory file
- inventory_template - path to inventory template to render with inventory_template_vars
- ips - list of IPs to run against
- ip - single ip

More options will be built in the future.

## Terraform versions

For Terraform v0.12.0+



## Usage

Single host:

```
resource "aws_instance" "this" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.this.id]

  key_name = aws_key_pair.this.key_name
  associate_public_ip_address = true
}

module "ansible" {
  source = "../../"
  ip = aws_instance.this.public_ip
  playbook_file_path = var.playbook_file_path
  roles_dir = "../ansible/roles"
  user = "ubuntu"
  private_key_path = var.private_key_path
}
```

Bastion host:

```
resource "aws_instance" "bastion" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.small"

  subnet_id = module.vpc.public_subnets[0]
  vpc_security_group_ids = [
    aws_security_group.this.id]

  associate_public_ip_address = true
  key_name = aws_key_pair.this.key_name

  tags = {
    Name = "bastion-${random_pet.this.id}"
  }
}

resource "aws_instance" "private" {
  count = 2

  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.small"

  subnet_id = module.vpc.private_subnets[0]
  vpc_security_group_ids = [
    aws_security_group.this.id]

  key_name = aws_key_pair.this.key_name

  tags = {
    Name = "private-${random_pet.this.id}-${count.index}"
  }
}

module "ansible" {
  source = "../../"

  ips = aws_instance.private.*.private_ip

  playbook_file_path = var.playbook_file_path
  roles_dir = "../ansible/roles"

  bastion_ip = aws_instance.bastion.public_ip
  bastion_user = "ubuntu"

  user = var.user
  private_key_path = var.private_key_path
}
```

With template:

```
resource "aws_instance" "this" {
  count = 3
  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.this.id]

  key_name = aws_key_pair.this.key_name
  associate_public_ip_address = true
}

module "ansible" {
  source = "../../"

  inventory_template = "${path.cwd}/ansible_inventory.tpl"

  inventory_template_vars = {
    host_ip_1 = aws_instance.this.*.public_ip[0]
    hostname_1 = "foo"
    hostname_1_vars = <<-EOT
    stuff = "things"
EOT

    hostname_2 = "bar"
    host_ip_2 = aws_instance.this.*.public_ip[1]
    hostname_3 = "baz"
    host_ip_3 = aws_instance.this.*.public_ip[2]
  }

  playbook_file_path = var.playbook_file_path
  user = "ubuntu"
  private_key_path = var.private_key_path
}
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Providers

| Name | Version |
|------|---------|
| aws | n/a |
| local | n/a |
| null | n/a |
| template | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| bastion\_ip | n/a | `string` | `""` | no |
| bastion\_user | n/a | `string` | `""` | no |
| cidr\_block\_matches | ########### ssh Config ########### | `list(string)` | <pre>[<br>  "10.*.*.*",<br>  "17.??.*.*",<br>  "192.168.*.*"<br>]</pre> | no |
| cleanup | ###### Other ###### | `bool` | `false` | no |
| inventory | n/a | `map(string)` | `{}` | no |
| inventory\_file | n/a | `string` | `""` | no |
| inventory\_map | n/a | `map(string)` | `{}` | no |
| inventory\_template | n/a | `string` | `""` | no |
| inventory\_template\_vars | n/a | `map(string)` | `{}` | no |
| ip | The elastic ip address of the node being configured. | `string` | `""` | no |
| ips | n/a | `list(string)` | n/a | yes |
| playbook\_file\_path | Absolute path to playbook file to configure the node | `string` | n/a | yes |
| playbook\_vars | Extra vars to include in run | `map(string)` | `{}` | no |
| private\_key\_path | Path to SSH private key to configure the node | `string` | n/a | yes |
| roles\_dir | Absolute path to roles directory to configure the node | `string` | `""` | no |
| user | The user used to configure the node | `string` | n/a | yes |
| verbose | n/a | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| ansible\_cfg | n/a |
| ansible\_sh | n/a |
| ip | n/a |
| ssh\_cfg | n/a |
| status | n/a |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Authors

Module managed by [robc-io](github.com/robc-io)

## Credits

- [Anton Babenko](https://github.com/antonbabenko)

## License

Apache 2 Licensed. See LICENSE for full details.