# Kamatera Toolbox Infrastructure as Code

Infrastructure as Code for Kamatera CloudCLI and 3rd party APIs and tools.

## Prerequisites

* [Terraform](https://www.terraform.io/downloads.html)
* [Python 3](https://www.python.org/downloads/)
* [Docker](https://docs.docker.com/get-docker/)
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* [Helm](https://helm.sh/docs/intro/install/)
* [Vault CLI](https://www.vaultproject.io/docs/install)

## Login

Set Vault credentials:

```
export VAULT_ADDR=
export VAULT_TOKEN=
```

Set environment variables and download secret files:

```
eval "$(bin/login.py ENVIRONMENT_NAME)"
```

## Usage

### Infrastructure

Environments are defined in `environments/` directory. Each environment has multiple sub-directories,
each corresponding to a module under `modules/`.

You can run Terraform commands for each environment/module combination using the following command:

```
bin/terraform.py ENVIRONMENT_NAME MODULE_NAME ...
```

For example:

```
bin/terraform.py ENVIRONMENT_NAME MODULE_NAME init
bin/terraform.py ENVIRONMENT_NAME MODULE_NAME plan
```

You can also run init and apply for all modules in an environment using the following command:

```
bin/terraform_init_apply.py ENVIRONMENT_NAME
```

See the help message for more options:

```
bin/terraform_init_apply.py --help
```
