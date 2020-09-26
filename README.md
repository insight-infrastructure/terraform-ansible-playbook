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

```hcl
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

```hcl
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

```hcl
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
| local | n/a |
| null | n/a |
| template | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| ask\_vault\_pass | ask for vault password | `bool` | `false` | no |
| bastion\_ip | The IP of the bastion host | `string` | `""` | no |
| bastion\_user | The bastion user name | `string` | `""` | no |
| become | Become root flag | `bool` | `true` | no |
| become\_method | privilege escalation method to use (default=%(default)s) | `string` | `"sudo"` | no |
| become\_user | The user to become | `string` | `"root"` | no |
| cidr\_block\_matches | CIDR blocks to use for the bastion host | `list(string)` | <pre>[<br>  "10.*.*.*",<br>  "17.??.*.*",<br>  "192.168.*.*"<br>]</pre> | no |
| cleanup | Debugging boolean to leave rendered files after call | `bool` | `false` | no |
| create | Boolean to ignore resource creation | `bool` | `true` | no |
| flush\_cache | clear the fact cache for every host in inventory | `bool` | `false` | no |
| force\_handlers | run handlers even if a task fails | `bool` | `false` | no |
| forks | specify number of parallel processes to use (default=5) | `number` | `5` | no |
| inventory | Not implemented | `map(string)` | `{}` | no |
| inventory\_file | The path to an inventory file | `string` | `""` | no |
| inventory\_template | The path to a template to run against | `string` | `""` | no |
| inventory\_template\_vars | A map of values to render the inventory template with | `map(string)` | `{}` | no |
| ip | The elastic ip address of the node being configured. | `string` | `""` | no |
| ips | A list of IPs to run against | `list(string)` | n/a | yes |
| module\_depends\_on | Any to have module depend on | `any` | n/a | yes |
| playbook\_file\_path | Absolute path to playbook file to configure the node | `string` | `""` | no |
| playbook\_template\_path | A path to a go templated playbook yml file | `string` | `""` | no |
| playbook\_template\_vars | A map of variables for the playbook go template | `map(string)` | `{}` | no |
| playbook\_vars | Extra vars to include in run | `map(any)` | `{}` | no |
| playbook\_vars\_file | A path to a json / yaml for extra vars | `string` | `""` | no |
| private\_key\_path | Path to SSH private key to configure the node | `string` | n/a | yes |
| requirements\_file\_path | The path to a requirements file for ansible galaxy | `string` | `""` | no |
| roles\_dir | Absolute path to roles directory to configure the node | `string` | `""` | no |
| scp\_extra\_args | specify extra arguments to pass to scp only (e.g. -l) | `string` | `""` | no |
| sftp\_extra\_args | specify extra arguments to pass to sftp only (e.g. -f, -l) | `string` | `""` | no |
| skip\_tags | only run plays and tasks whose tags do not match these values | `string` | `""` | no |
| ssh\_common\_args | specify common arguments to pass to sftp/scp/ssh (e.g. ProxyCommand) | `string` | `""` | no |
| ssh\_extra\_args | specify extra arguments to pass to ssh only (e.g. -R) | `string` | `"-p 22 -o ConnectTimeout=10 -o ConnectionAttempts=10 -o StrictHostKeyChecking=no -o IdentitiesOnly=yes"` | no |
| start\_at\_task | start the playbook at the task matching this name | `string` | `""` | no |
| step | one-step-at-a-time: confirm each task before running | `bool` | `false` | no |
| tags | only run plays and tasks tagged with these values | `string` | `""` | no |
| user | The user used to configure the node | `string` | n/a | yes |
| vault\_id | the vault identity to use | `string` | `""` | no |
| vault\_password\_file | vault password file | `string` | `""` | no |
| verbose | Boolean to force verbose mode on ansible call | `bool` | `false` | no |

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