# Pulled Dec 12, 2022
FROM python:3.8@sha256:e411647c253b75948394a343b13ff32b5674687df0c54187445d12ee9de2b106
RUN wget http://ftp.fr.debian.org/debian/pool/main/c/ca-certificates/ca-certificates_20230311_all.deb &&\
    dpkg -i ca-certificates_20230311_all.deb &&\
    rm ca-certificates_20230311_all.deb
RUN pip install --upgrade pip && pip install certbot-dns-cloudflare
RUN echo installing kubectl &&\
    curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.24.2/bin/linux/amd64/kubectl &&\
    chmod +x ./kubectl &&\
    mv ./kubectl /usr/local/bin/kubectl
COPY certbot_.py /usr/local/bin/certbot_.py
