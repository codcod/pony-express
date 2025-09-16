#!/bin/bash

# Build script for Pony compiler Docker image
# This script builds the multistage Dockerfile and creates a base image for Pony development

set -e

IMAGE_NAME="pony-base"
TAG="latest"
DOCKERFILE="Dockerfile.multistage"

echo "Building Pony compiler base image..."
echo "Image: ${IMAGE_NAME}:${TAG}"
echo "Dockerfile: ${DOCKERFILE}"
echo ""

# Build the image
docker build -t "${IMAGE_NAME}:${TAG}" -f "${DOCKERFILE}" .

echo ""
echo "Build completed successfully!"
echo ""
echo "Testing the image..."

# Test the image by running ponyc --version
docker run --rm "${IMAGE_NAME}:${TAG}" ponyc --version

echo ""
echo "Image is ready for use!"
echo ""
echo "Usage examples:"
echo "  # Run interactive shell in the container:"
echo "  docker run -it --rm -v \$(pwd):/workspace ${IMAGE_NAME}:${TAG}"
echo ""
echo "  # Compile a Pony program:"
echo "  docker run --rm -v \$(pwd):/workspace ${IMAGE_NAME}:${TAG} ponyc /workspace/your_program.pony"
echo ""
echo "  # Run with docker-compose:"
echo "  docker-compose up"