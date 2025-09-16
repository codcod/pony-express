#!/bin/bash
# Build script for Pony base image

set -e

# Configuration
IMAGE_NAME="pony-base"
DOCKERFILE="Dockerfile.base"
BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
BUILD_VERSION="0.59.0"
BUILD_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Parse command line arguments
PUSH=false
NO_CACHE=false
TAG_LATEST=true

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--push)
            PUSH=true
            shift
            ;;
        -n|--no-cache)
            NO_CACHE=true
            shift
            ;;
        --no-latest)
            TAG_LATEST=false
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  -p, --push       Push image to registry after build"
            echo "  -n, --no-cache   Build without cache"
            echo "  --no-latest      Don't tag as latest"
            echo "  -h, --help       Show this help"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    log_error "Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if Dockerfile exists
if [[ ! -f "$DOCKERFILE" ]]; then
    log_error "Dockerfile not found: $DOCKERFILE"
    exit 1
fi

log_info "Building Pony base image..."
log_info "Image name: ${IMAGE_NAME}:${BUILD_VERSION}"
log_info "Build date: $BUILD_DATE"
log_info "Build commit: $BUILD_COMMIT"

# Build command
BUILD_ARGS=(
    "--build-arg" "BUILD_DATE=$BUILD_DATE"
    "--build-arg" "BUILD_VERSION=$BUILD_VERSION"
    "--build-arg" "BUILD_COMMIT=$BUILD_COMMIT"
    "--file" "$DOCKERFILE"
    "--tag" "${IMAGE_NAME}:${BUILD_VERSION}"
)

if [[ "$TAG_LATEST" == "true" ]]; then
    BUILD_ARGS+=("--tag" "${IMAGE_NAME}:latest")
fi

if [[ "$NO_CACHE" == "true" ]]; then
    BUILD_ARGS+=("--no-cache")
    log_warning "Building without cache - this will take longer"
fi

# Add current directory as build context
BUILD_ARGS+=(".")

# Execute build
log_info "Starting Docker build..."
if docker build "${BUILD_ARGS[@]}"; then
    log_success "Build completed successfully!"
    
    # Show image information
    log_info "Image details:"
    docker images "${IMAGE_NAME}" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
    
    # Test the image
    log_info "Testing the built image..."
    if docker run --rm "${IMAGE_NAME}:${BUILD_VERSION}" ponyc --version; then
        log_success "Image test passed!"
    else
        log_error "Image test failed!"
        exit 1
    fi
    
    # Push if requested
    if [[ "$PUSH" == "true" ]]; then
        log_info "Pushing image to registry..."
        docker push "${IMAGE_NAME}:${BUILD_VERSION}"
        if [[ "$TAG_LATEST" == "true" ]]; then
            docker push "${IMAGE_NAME}:latest"
        fi
        log_success "Image pushed successfully!"
    fi
    
else
    log_error "Build failed!"
    exit 1
fi

log_success "All operations completed successfully!"

# Show usage examples
echo ""
log_info "Usage examples:"
echo "  # Interactive development:"
echo "  docker run -it --rm -v \$(pwd):/workspace ${IMAGE_NAME}:${BUILD_VERSION}"
echo ""
echo "  # Compile a Pony application:"
echo "  docker run --rm -v \$(pwd):/workspace ${IMAGE_NAME}:${BUILD_VERSION} pony-dev compile src"
echo ""
echo "  # Use as base in your own Dockerfile:"
echo "  FROM ${IMAGE_NAME}:${BUILD_VERSION}"

