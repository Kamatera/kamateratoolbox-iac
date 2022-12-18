# Kamatera Toolbox Infrastructure as Code

Infrastructure as Code for Kamatera CloudCLI and 3rd party APIs and tools.

## Prerequisites

* [Terraform](https://www.terraform.io/downloads.html)
* [Python 3](https://www.python.org/downloads/)
* [Docker](https://docs.docker.com/get-docker/)
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* [Helm](https://helm.sh/docs/intro/install/)
* [Vault CLI](https://www.vaultproject.io/docs/install)
* [ArgoCD CLI](https://argo-cd.readthedocs.io/en/stable/cli_installation/)

## Login

```
eval "$(bin/login.py <ENVIRONMENT_NAME> [SUB_ENVIRONMENT_NAME])"
```

Follow the instructions to setup your credentials

## Usage

### Infrastructure

You can run Terraform commands in the context of the current environment / sub environment using `bin/terraform.py`, 
it ensures that the correct backend and vars are set for the environment / sub environment.

For example:

```
bin/terraform.py init
bin/terraform.py apply
```

See the help message for more options:

```
bin/terraform.py --help
```

Terraform variables should be stored in Vault under the following keys:

* For the root environment: `iac/terraform/tf_vars`
* For sub environments: `iac/terraform/tf_vars_SUB_ENVIRONMENT_NAME`
