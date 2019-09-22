# terraform-aws-icon-node-configuration

Terraform module for configuring ICON nodes after bringup. Module is intended to be run via Terragrunt, a Terraform wrapper.

Currently, this module supports running user supplied Ansible playbooks to configure the node after bringup.


### What is needed to run the module

Consumer of the module will need to install ansible on the provisioning system, either via the package manager of the system, or via pip.


### Inputs required to run the module

The module requires following inputs to run:

- Name of the module.
	* ``name``
	* Default: "node-configuration"

- Environment this module is being run in.
	* ``environment``
	* This will usually be defined in the terragrunt.hcl file in the project root.

- Configuring User:
	* ``config_user``
	* The user name used to configure the node.

- Configuring SSH Private Key:
	* ``config_private_key``
	* The SSH private key to connect to the node being configured.

- Path to playbook file:
	* ``config_playbook_file``
	* Absolute path to the playbook being run to configure the node.

- Path to roles directory:
	* ``config_playbook_roles_dir``
	* Absolute path to the roles directory to configure the node.

- Elastic IP of the node being configured:
	* ``eip``
	* The elastic ip address of the node being configured.

- Tags
	* ``tags``
	* Any tags the consumer of the module would like to put in.


### Outputs from the module

The module will output the string "Node Configured," and the elastic IP of the node that was configured.


### Recommended way to run the module

To support DRY practices in Terraform, following way is recommended to run the module.

As an example, following directory tree represents root of the terragrunt project directory.

```
.
├── terragrunt.hcl
├── configure.tfvars
└── sub_project_dir
    ├── more_sub_project_dir
    │   └── terragrunt.hcl

```

Assuming that the consumer is utilizing this module from the directory ``more_sub_project_dir``, following block should be added to the ``terragrunt.hcl`` file
under this directory. This will make sure that terragrunt will be walking up the project directory until it hits the root directory to get the required variables.

```
include {
  path = find_in_parent_folders()
}
```

Assuming that the ``terragrunt.hcl`` file under the root directory has a ``terraform { }`` section to source the ``extra_arguments`` for the whole project, add
following line to the ``terragrunt.hcl`` file under to the list ``required_var_files`` as follows.

```
terraform {
  extra_arguments "vars" {
    ...
    required_var_files {
       ...
      "${get_parent_terragrunt_dir()}/${path_relative_to_include()}/${find_in_parent_folders("configure.tfvars")}",
       ...
    }
    ...
  }
}

```

Finally, add the configure.tfvars in the root directory of the project to provide the variables required to run the module. Make sure to gitignore the file.

```
 Example configure.tfvars file

config_user = "some_user"
config_private_key = "/absolute/path/to/ssh private key/file"
config_playbook_file = "/absolute/path/to/playbook/file"
config_playbook_roles_dir = "/absolute/path/to/roles/directory"
```

### Examples

An example of the structure of playbook and roles directory is included under examples directory.


### Future Features

- Support configuration via Bastion Host


### What this doesn't include

- This module does not include the ansible playbooks to run. The consumer is expected to bring their own ansible playbooks and roles.
