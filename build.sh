#!/bin/bash
set -euo pipefail

# ==========================================
# 1. Global Definitions
# ==========================================
declare -A imgName=(
    ["Dockerfile.base"]="kflyn825/tool-base:latest"
    ["Dockerfile.dep"]="kflyn825/tool-dep:latest"
    ["Dockerfile.dev"]="kflyn825/embed-dev:latest"
)

declare -A version=(
    ["Dockerfile.base"]="1.0"
    ["Dockerfile.dep"]="1.0"
    ["Dockerfile.dev"]="1.0"
)

# Standard indexed array guarantees execution order (0 -> 1 -> 2)
declare -a DockerfileArray=(
    "Dockerfile.base"
    "Dockerfile.dep"
    "Dockerfile.dev"
)

# ==========================================
# 2. Functions
# ==========================================

usage() {
    {
        echo "Usage: $0 [Dockerfile] | [index of DockerfileArray]"
        echo ""
        echo "If no arguments are provided, ALL images will be built in sequence."
        echo ""
        echo "Available Dockerfiles:"
        for (( i=0; i<${#DockerfileArray[@]}; i++ )); do
            echo "  [$i] ${DockerfileArray[$i]}"
        done
        echo ""
        echo "Example building a specific file:"
        echo "  $0 Dockerfile.base"
        echo "  $0 0"
    } >&2
    exit 1
}

resolve_dockerfile() {
    local input="$1"
    
    # Check if input is a valid numeric index within bounds
    if [[ "$input" =~ ^[0-9]+$ ]] && (( input < ${#DockerfileArray[@]} )); then
        echo "${DockerfileArray[$input]}"
    # Check if input is a valid Dockerfile key
    elif [[ -n "${imgName[$input]+isset}" ]]; then
        echo "$input"
    else
        echo "Error: Invalid Dockerfile or index provided: '$input'" >&2
        usage
    fi
}

build_image() {
    local dockerfile="$1"
    local target_img="${imgName[$dockerfile]}"
    local target_ver="${version[$dockerfile]}"

    echo "=========================================="
    echo ">>> Building Image: ${target_img}"
    echo ">>> Dockerfile:     ${dockerfile}"
    echo ">>> Version:        ${target_ver}"
    echo "=========================================="

    docker buildx build \
        --builder default \
        --progress=plain \
        --pull=false \
        --load \
        -f "${dockerfile}" \
        -t "${target_img}" \
        --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
        --build-arg VERSION="${target_ver}" \
        --build-arg UID="$(id -u)" \
        --build-arg GID="$(id -g)" \
        --build-arg USERNAME="$(id -u -n)" \
        --label maintainer="kflyn825@outlook.com" \
        --label version="${target_ver}" \
        .
}

build_all_images() {
    echo ">>> No arguments provided. Building all images in order..."
    
    for df in "${DockerfileArray[@]}"; do
        build_image "$df"
    done
    
    echo ">>> All images built successfully."
}

# ==========================================
# 3. Main Execution
# ==========================================
main() {
    if [[ $# -eq 0 ]]; then
        build_all_images
        exit 0
    fi

    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        usage
    fi

    local selected_dockerfile
    selected_dockerfile=$(resolve_dockerfile "$1")
    
    build_image "${selected_dockerfile}"
}

main "$@"