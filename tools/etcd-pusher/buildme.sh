#!/usr/bin/env bash

IMAGE_ORG="17media"
IMAGE_REPO="pusher"
IMAGE_TAG="v$(date +%y.%-m.%-d)"

docker build -t ${IMAGE_ORG}/${IMAGE_REPO}:${IMAGE_TAG} .

echo "==> Docker image built successfully, please push the image manually:"
echo "==> $ docker push ${IMAGE_ORG}/${IMAGE_REPO}:${IMAGE_TAG}"
