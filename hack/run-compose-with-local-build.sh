#!/usr/bin/env bash

# This script builds the schema, then tears down and rebuilds
# the local podman-compose development environment.
#
# It is intended to be run from the root of the project.

set -e

PROFILE=sbomer

echo "--- Checking Minikube status (Profile: $PROFILE) ---"

if ! minikube -p "$PROFILE" status > /dev/null 2>&1; then
    error "Minikube cluster '$PROFILE' is NOT running."
    echo ""
    echo "Please run the setup script first to start the cluster and install dependencies:"
    echo "./hack/setup-minikube.sh (and please leave it running so that the cluster can be exposed to the host at port 8001)"
    echo "If window was already closed, please run: kubectl proxy --port=8001 --address='0.0.0.0' --accept-hosts='^.*$'"
    echo "This enables the system to connect to the minikube cluster"
    echo ""
    exit 1
fi


echo "--- Detecting Minikube Network Gateway ---"
# Get Minikube IP (e.g. 192.168.49.2)
MINIKUBE_IP=$(minikube -p $PROFILE ip)

# Calculate Gateway IP (Replace last octet with .1)
# This works for standard Minikube networking logic
GATEWAY_IP="${MINIKUBE_IP%.*}.1"

echo "Minikube IP: $MINIKUBE_IP"
echo "Host Gateway: $GATEWAY_IP"

# Export for podman-compose to pick up
export SBOMER_STORAGE_URL="http://${GATEWAY_IP}:8085"

# Path to compose file
COMPOSE_FILE="./podman/podman-compose.yml"

echo "--- Apply own local syft generator task to Minikube ---"
bash ./hack/apply-local-syft-generator-task-to-minikube.sh

echo "--- Building local syft-agent image inside of Minikube ---"
bash ./hack/build-local-syft-agent-into-minikube.sh

echo "--- Building the component with schemas ---"
bash ./hack/build-with-schemas.sh

echo "--- Switching to sbomer-local-dev folder ---"
pushd sbomer-local-dev

# podman-compose -f podman-compose.yml -f ../../podman/podman-compose.override.yaml down -v
# Run podman-compose with override compose file that builds syft-generator component locally instead of Quay latest
# podman-compose -f podman-compose.yml -f ../../podman/podman-compose.override.yaml up --build
bash run-compose.sh --override ../podman/podman-compose.override.yaml

echo "--- Local podman-compose is now running ---"