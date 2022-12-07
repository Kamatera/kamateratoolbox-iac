# Kamatera Toolbox Infrastructure as Code

Infrastructure as Code for Kamatera CloudCLI and 3rd party APIs and tools.

## Prerequisites

* [Terraform](https://www.terraform.io/downloads.html)
* [Python 3](https://www.python.org/downloads/)
* [Docker](https://docs.docker.com/get-docker/)
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* [Helm](https://helm.sh/docs/intro/install/)

## Login

Set secrets in env vars:

```
# Kamatera admin credentials
export KAMATERA_API_CLIENT_ID=
export KAMATERA_API_SECRET=
# Rancher admin credentials
export RANCHER_ACCESS_KEY=
export RANCHER_SECRET_KEY=
# lower level access key for node management, you can get it from the Rancher default node templates
export KAMATERA_NODE_MANAGEMENT_API_CLIENT_ID=
export KAMATERA_NODE_MANAGEMENT_API_SECRET=
# cloudflare restricted token with Zone:DNS:Edit permissions for relevant domain
export CLOUDFLARE_API_TOKEN=
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
