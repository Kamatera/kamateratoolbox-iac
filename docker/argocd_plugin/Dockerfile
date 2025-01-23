FROM quay.io/argoproj/argocd:v2.13.3
USER root
RUN apt update && apt install -y python3 python3-pip curl
RUN pip install kubernetes==31.0.0
USER 999
COPY argocd_iac_plugin.py /usr/local/bin/argocd_iac_plugin.py
