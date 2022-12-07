# Bootstrap

This document describes how to create a new environment from scratch.

Set environment name in env var to be used in following commands. The name must be only lowercase
letters:

```
ENVIRONMENT_NAME=
```

Prerequisites:

* Follow the [README](../README.md) prerequisites and login steps.

Duplicate an existing environment directory to directory `environments/$ENVIRONMENT_NAME`

Delete all .terraform subdirectories:

```
find environments/$ENVIRONMENT_NAME -type d -name .terraform | xargs rm -rf
```

Create a `defaults.terraform.tfvars` file in the new environment directory with the following content.

```
defaults = {
  // default values
}
```

Replace default values with a map of values as needed for the environment's modules.

You can add the kubeconfig file to your local kubeconfig file using the following command:

```
cp ~/.kube/config ~/.kube/config.$(date +%Y-%m-%d).bak &&\
KUBECONFIG=<(bin/terraform.py main cloudcli output -raw kubeconfig):~/.kube/config kubectl config view --flatten \
    > ~/.kube/config.new &&\
mv ~/.kube/config.new ~/.kube/config
```
