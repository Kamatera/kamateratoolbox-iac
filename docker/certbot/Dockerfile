# Pulled Dec 12, 2022
FROM python:3.8@sha256:7c5b3ec91b7e4131dead176d824ddf317e6c19fe1ae38c54ec0ae6038908dd18
RUN pip install --upgrade pip && pip install certbot-dns-cloudflare
RUN echo installing kubectl &&\
    curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.24.2/bin/linux/amd64/kubectl &&\
    chmod +x ./kubectl &&\
    mv ./kubectl /usr/local/bin/kubectl
COPY certbot_.py /usr/local/bin/certbot_.py
