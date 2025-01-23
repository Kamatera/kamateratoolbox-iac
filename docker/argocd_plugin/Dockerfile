FROM python:3.8@sha256:d411270700143fa2683cc8264d9fa5d3279fd3b6afff62ae81ea2f9d070e390c
RUN pip install kubernetes==31.0.0
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
COPY argocd_iac_plugin.py /usr/local/bin/argocd_iac_plugin.py
COPY plugin.yaml /home/argocd/cmp-server/config/plugin.yaml
