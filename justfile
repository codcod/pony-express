# https://just.systems

PONY_VERSION := "0.59.0"
EXECUTABLE := "pony-express"
BUILD_DIR := "build"

@_:
   just --list

# Create a base image with Ponyc installed
[group('build')]
base-image:
    docker build \
        --build-arg PONY_VERSION={{PONY_VERSION}} \
        -t codcod/ponyc:{{PONY_VERSION}} \
        -f Dockerfile.base .

# Compile the Pony source code using the base image
[group('build')]
compile-base-image:
    docker run --rm -v "$(pwd)":/workspace \
        -w /workspace \
        codcod/ponyc:{{PONY_VERSION}} ponyc \
        --path /usr/local/lib/pony/{{PONY_VERSION}}/packages src

# Compile the Pony source code using ponyc installed locally
[group('build')]
compile:
    ponyc \
        --bin-name {{EXECUTABLE}} \
        --output {{BUILD_DIR}} \
        src

# Clean the build directory
[group('build')]
clean:
    rm -rf ./{{BUILD_DIR}}

# Run the compiled executable
[group('run')]
run:
    ./{{BUILD_DIR}}/{{EXECUTABLE}}

# Run performance tests with plow
# http://127.0.0.1:18888
[group('qa')]
perf:
    plow http://127.0.0.1:8080/api/v1/messages/send \
        -c 200 \
        --body @tests/message.json \
        -T 'application/json' \
        -m POST
