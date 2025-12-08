#!/bin/bash

# Exit immediately if a command fails
set -e

# Variables for minikube profile and syft-agent
SYFT_AGENT_IMAGE="syft-agent:latest"
PROFILE="sbomer"
TAR_FILE="syft-agent.tar"

echo "--- Building and inserting syft-agent image into Minikube registry ---"

podman build --format docker -t "$SYFT_AGENT_IMAGE" -f podman/syft-agent/Containerfile .

echo "--- Exporting syft-agent image to archive ---"
if [ -f "$TAR_FILE" ]; then
    rm "$TAR_FILE"
fi
podman save -o "$TAR_FILE" "$SYFT_AGENT_IMAGE"

echo "--- Loading syft-agent into Minikube ---"
# This sends the file to Minikube
minikube -p "$PROFILE" image load "$TAR_FILE"

echo "--- Cleanup ---"
rm "$TAR_FILE"

echo "Done! Image '$SYFT_AGENT_IMAGE' is ready in cluster '$PROFILE'."