import os
import sys
import json
import base64
import subprocess
from textwrap import dedent


def main(vault_addr, admin_user):
    p = subprocess.run([
        "kubectl", "-n", "kube-system", "get", "secret", "vault", "-o", "json"
    ], stdout=subprocess.PIPE)
    if p.returncode == 0:
        data = json.loads(p.stdout)['data']
        root_token = base64.b64decode(data['root_token'].encode()).decode()
    else:
        print("Initializing vault...")
        res = json.loads(subprocess.check_output([
            "kubectl", "-n", "vault", "exec", "-c", "vault", "deployment/vault",
            "--", "vault", "operator", "init", "--address=http://localhost:8200", "-format=json"
        ]))
        unseal_keys = res['unseal_keys_hex']
        root_token = res['root_token']
        print("Saving initial root token and unseal keys in namespace 'kube-system', secret 'vault'")
        subprocess.check_call([
            "kubectl", "-n", "kube-system", "create", "secret", "generic", "vault",
            "--from-literal=root_token={}".format(root_token),
            *[
                f"--from-literal=unseal_key_{i+1}={key}"
                for i, key in enumerate(unseal_keys)
            ]
        ])
        print("Saving 3 unseal keys for vault auto unseal")
        subprocess.check_call([
            "kubectl", "-n", "vault", "create", "secret", "generic", "vault-unseal",
            f"--from-literal=UNSEAL_KEYS={' '.join(unseal_keys[:3])}"
        ])
        print("Restarting vault")
        subprocess.check_call([
            "kubectl", "-n", "vault", "rollout", "restart", "deployment", "vault"
        ])
    env = {**os.environ, "VAULT_ADDR": vault_addr, "VAULT_TOKEN": root_token}
    cmd = dedent(f'''
        if ! vault secrets list | grep '^kv/ '; then
            vault secrets enable -path=kv kv
        fi &&\
        if ! vault auth list | grep '^approle/ '; then
            vault auth enable -path=approle approle
        fi &&\
        if ! vault auth list | grep '^userpass/ '; then
            vault auth enable -path=userpass userpass
        fi &&\
        echo 'path "kv/*" {{
          capabilities = [ "read", "list" ]
        }}' | vault policy write readonly - &&\
        echo 'path "*" {{
          capabilities = ["create", "read", "update", "delete", "list", "sudo"]
        }}' | vault policy write admin - &&\
        if ! vault read -field=policies auth/userpass/users/{admin_user}; then
            echo Missing admin user, please create it manually by running the following commands:
            echo '  VAULT_USER_PASSWORD=<YOUR_PASSWORD>'
            echo '  VAULT_ADDR={vault_addr} VAULT_TOKEN={root_token} vault write auth/userpass/users/{admin_user} password=$VAULT_USER_PASSWORD policies=admin'
            exit 1
        fi &&\
        USERPASS_ACCESSOR="$(vault auth list -format=json | jq -r '.["userpass/"].accessor')" &&\
        APPROLE_ACCESSOR="$(vault auth list -format=json | jq -r '.["approle/"].accessor')" &&\
        ADMIN_USER_ENTITY_ID="$(vault write -format=json identity/entity name="user {admin_user}" | jq -r .data.id)" &&\
        if [ "$ADMIN_USER_ENTITY_ID" != "" ]; then
            vault write identity/entity-alias name={admin_user} canonical_id=$ADMIN_USER_ENTITY_ID mount_accessor=$USERPASS_ACCESSOR
        fi &&\
        if ! kubectl -n argocd get secret argocd-vault-plugin-credentials; then
            vault write auth/approle/role/argocd token_ttl=1h token_max_ttl=4h &&\
            ARGOCD_SECRET_ID="$(vault write -f -format=json auth/approle/role/argocd/secret-id | jq -r .data.secret_id)" &&\
            ARGOCD_ROLE_ID="$(vault read -format=json auth/approle/role/argocd/role-id | jq -r .data.role_id)" &&\
            ARGOCD_ENTITY_ID="$(vault write -format=json identity/entity name="approle argocd" policies=readonly | jq -r .data.id)" &&\
            if [ "ARGOCD_ENTITY_ID" != "" ]; then
                vault write identity/entity-alias name=$ARGOCD_ROLE_ID canonical_id=$ARGOCD_ENTITY_ID mount_accessor=$APPROLE_ACCESSOR
            fi
            kubectl -n argocd create secret generic argocd-vault-plugin-credentials \
                --from-literal=AVP_ROLE_ID=$ARGOCD_ROLE_ID \
                --from-literal=AVP_SECRET_ID=$ARGOCD_SECRET_ID \
                --from-literal=VAULT_ADDR={vault_addr} &&\
            kubectl -n argocd rollout restart deployment argocd-repo-server
        fi &&\
        if ! kubectl -n vault get secret vaultbackup; then
            VAULT_EXPORT_ENCRYPTION_PASSWORD="$(pwgen -1 64)" &&\
            vault kv put -mount=kv iac/vault/export encryption_password=$VAULT_EXPORT_ENCRYPTION_PASSWORD &&\
            vault write auth/approle/role/vaultbackup token_ttl=1h token_max_ttl=4h &&\
            SECRET_ID="$(vault write -f -format=json auth/approle/role/vaultbackup/secret-id | jq -r .data.secret_id)" &&\
            ROLE_ID="$(vault read -format=json auth/approle/role/vaultbackup/role-id | jq -r .data.role_id)" &&\
            ENTITY_ID="$(vault write -format=json identity/entity name="approle vaultbackup" policies=readonly | jq -r .data.id)" &&\
            if [ "ENTITY_ID" != "" ]; then
                vault write identity/entity-alias name=$ROLE_ID canonical_id=$ENTITY_ID mount_accessor=$APPROLE_ACCESSOR
            fi
            kubectl -n vault create secret generic vaultbackup \
                --from-literal=AVP_ROLE_ID=$ROLE_ID \
                --from-literal=AVP_SECRET_ID=$SECRET_ID \
                --from-literal=VAULT_ADDR={vault_addr} \
                --from-literal=VAULT_EXPORT_ENCRYPTION_PASSWORD=$VAULT_EXPORT_ENCRYPTION_PASSWORD
        fi
    ''')
    retcode = subprocess.call(cmd, shell=True, env=env)
    if retcode != 0:
        exit(retcode)


if __name__ == '__main__':
    main(*sys.argv[1:])
