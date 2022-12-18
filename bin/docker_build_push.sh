#!/usr/bin/env bash

DOCKER_SUB_PATH="${1}"

HELP="Usage: bin/docker_build_push.sh <docker_sub_path>"

if [ "${DOCKER_SUB_PATH}" == "argocd_plugin" ]; then
  TAG_SUFFIX="argocd-plugin"
elif [ "${DOCKER_SUB_PATH}" == "certbot" ]; then
  TAG_SUFFIX="certbot"
elif [ "${DOCKER_SUB_PATH}" == "vault_export" ]; then
  TAG_SUFFIX="vault-export"
else
  echo "ERROR! Unknown docker sub path: '${DOCKER_SUB_PATH}'"
  echo "${HELP}"
  exit 1
fi

DOCKER_BUILD_PATH="docker/${DOCKER_SUB_PATH}"
COMMIT_SHA="$(git log -n 1 --pretty=format:"%H")"
TAG_IMAGE="ghcr.io/kamatera/kamateratoolbox-iac-${TAG_SUFFIX}:${COMMIT_SHA}"

echo "Building and pushing image from path '${DOCKER_BUILD_PATH}'" &&\
docker build -t $TAG_IMAGE $DOCKER_BUILD_PATH &&\
docker push $TAG_IMAGE &&\
echo "Image pushed to $TAG_IMAGE"
