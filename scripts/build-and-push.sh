#!/bin/bash

# Build and push Odoo Docker image script
# Usage: ./build-and-push.sh [registry-url] [image-tag]

set -e

REGISTRY=${1:-"your-registry.com"}
TAG=${2:-"latest"}
IMAGE_NAME="odoo"

echo "Building Odoo Docker image..."
docker build -t $REGISTRY/$IMAGE_NAME:$TAG .

echo "Tagging image..."
docker tag $REGISTRY/$IMAGE_NAME:$TAG $REGISTRY/$IMAGE_NAME:latest

echo "Pushing image to registry..."
docker push $REGISTRY/$IMAGE_NAME:$TAG
docker push $REGISTRY/$IMAGE_NAME:latest

echo "Image pushed successfully!"
echo "Update your Kubernetes deployment to use: $REGISTRY/$IMAGE_NAME:$TAG"
