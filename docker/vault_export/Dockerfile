# Pulled 11 Dec, 2022
FROM python:3.8@sha256:300af00b63fc735ec85a1a8305e2bd0a5d3477c1857fdf135c8eb49d09479387
RUN apt-get update && apt-get install -y lsb-release libcap2-bin jq &&\
    wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor > /usr/share/keyrings/hashicorp-archive-keyring.gpg &&\
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" > /etc/apt/sources.list.d/hashicorp.list &&\
    apt-get update && apt-get install -y vault &&\
    setcap cap_ipc_lock= `which vault`
COPY vault_export.py /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/vault_export.py"]
