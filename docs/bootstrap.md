# Bootstrap

This document describes how to create a new environment from scratch.

Set environment name in env var to be used in following commands. The name must be only lowercase
letters:

```
ENVIRONMENT_NAME=
```

Install the [README](../README.md) prerequisites

Set env vars:

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

# vault admin token
export VAULT_ADDR=
export VAULT_TOKEN=

# terraform state DB connection string
export STATE_DB_CONN_STRING=postgres://user:pass@db.example.com/terraform_backend

# access key for the autoscaler, this has to be a full access key
export KAMATERA_AUTOSCALER_API_CLIENT_ID=
export KAMATERA_AUTOSCALER_API_SECRET=
```

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

### Vault

* Create policies:

**readonly**

```
path "kv/data/*" {
  capabilities = [ "read" ]
}
```

**admin**

```
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
```

* Enable user auth method
* Enable approle auth method
* Create userpass user for yourself
* Create entity for yourself with admin policy
* Add alias to your entity for your userpass user
* Log-in as your user
* Create an approle for argocd:
  * `vault write auth/approle/role/argocd token_ttl=1h token_max_ttl=4h`
  * `vault write -f auth/approle/role/argocd/secret-id`
  * Get the role-id: `vault read auth/approle/role/argocd/role-id`
  * Create a secret in namespace `argocd` named `argocd-vault-plugin-credentials` with the following content:
    * `AVP_ROLE_ID`
    * `AVP_SECRET_ID`
    * `VAULT_ADDR`
  * Create entity for this approle with readonly policy
  * Add alias to this entity for the approle role id
* Enable kv secrets engine at `kv`
* Set your user's token in env var `VAULT_TOKEN`
* Create another approle for vault backup:
  * same procedure as the argocd approle, except name it as `vaultbackup`
  * create the secret in namespace `vault` named `vaultbackup`
* Create a secret in Vault under `iac/vault/export` with key `encryption_password` containing a random password
  for encrypting the vault backup
* Set this password in the `vaultbackup` secret as `VAULT_EXPORT_ENCRYPTION_PASSWORD`

### Terraform State DB

Create a Vault secret at `iac/terraform` with the following keys:

* `backend-db-password`: generate a password using `pwgen -s 32 1`
* `state_db_server.key` / `state_db_server.crt`: generate a self-signed certificate using:
  * `openssl req -new -x509 -days 365 -nodes -text -out server.crt -keyout server.key -subj "/CN=terraform-state-db.localhost"`

Sync the Terraform argocd APP

After DB pod is running, restart it to force ssl connection to be used.

Set state db connection string env var:

```
export STATE_DB_CONN_STRING=postgres://postgres:PASSWORD@cloudcli-default-ingress.DOMAIN:9941/postgres
```

edit relevant terraform environment and set to `pg` backend.

Run init and migrate the state to the remote backend.

You can delete the tfstate files.

### Certbot

Set vault secret at `iac/cloudflare` with key `api_token` and value of your Cloudflare API token.

### Monitoring

Set sendgrid secret at `iac/sendgrid` with the following keys:
* `user` / `password` - api smtp relay integration username/password
* `from_address` - for notification emails

Setup Grafana:

* Login at https://cloudcli-grafana.ROOT_DOMAIN with username `admin`, password `prom-operator`
* Change admin password to a secure one
* Create a user for yourself, set it to global Admin role and to workspace default as admin.
* Edit alerting contact points and set your email to the default contact point and test it.

### Save secrets to Vault

Save all environment var secret values to Vault:

```
vault kv put -mount=kv iac/terraform/env \
  KAMATERA_API_CLIENT_ID=$KAMATERA_API_CLIENT_ID \
  KAMATERA_API_SECRET=$KAMATERA_API_SECRET \
  RANCHER_ACCESS_KEY=$RANCHER_ACCESS_KEY \
  RANCHER_SECRET_KEY=$RANCHER_SECRET_KEY \
  KAMATERA_NODE_MANAGEMENT_API_CLIENT_ID=$KAMATERA_NODE_MANAGEMENT_API_CLIENT_ID \
  KAMATERA_NODE_MANAGEMENT_API_SECRET=$KAMATERA_NODE_MANAGEMENT_API_SECRET \
  CLOUDFLARE_API_TOKEN=$CLOUDFLARE_API_TOKEN \
  STATE_DB_CONN_STRING=$STATE_DB_CONN_STRING \
  KAMATERA_AUTOSCALER_API_CLIENT_ID=$KAMATERA_AUTOSCALER_API_CLIENT_ID \
  KAMATERA_AUTOSCALER_API_SECRET=$KAMATERA_AUTOSCALER_API_SECRET
```

Save the default.terraform.tfvars file to Vault:

```
vault kv put -mount=kv iac/terraform/default-tfvars \
  tfvars=@environments/$ENVIRONMENT_NAME/defaults.terraform.tfvars
```

Save the kubeconfig file to Vault:

```
vault kv put -mount=kv iac/terraform/kubeconfig \
  kubeconfig="$(bin/terraform.py main core output -raw kubeconfig)"
```