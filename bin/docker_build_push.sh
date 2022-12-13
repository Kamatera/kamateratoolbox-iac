#!/usr/bin/env bash

TAG_SUFFIX="${1}"
DOCKER_BUILD_PATH="${2}"

if [ -z "${TAG_SUFFIX}" ] || [ -z "${DOCKER_BUILD_PATH}" ]; then
    echo "Usage: $0 <tag_suffix> <docker_build_path>"
    exit 1
fi

COMMIT_SHA="$(git log -n 1 --pretty=format:"%H")"
TAG_IMAGE="ghcr.io/kamatera/kamateratoolbox-iac-${TAG_SUFFIX}:${COMMIT_SHA}"
docker build -t $TAG_IMAGE $DOCKER_BUILD_PATH &&\
docker push $TAG_IMAGE &&\
echo "Image pushed to $TAG_IMAGE"
