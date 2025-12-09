#!/bin/bash
set -e

# If a change was made to the syft-generation-task.yaml in the helm chart, please use this script to apply the change to minikube

# Apply local TaskRun to Minikube for Syft generation
CHART_PATH="./helm/syft-generator-chart"
OUTPUT_DIR="./tmp"
OUTPUT_FILE="${OUTPUT_DIR}/syft-generation-task.yaml"

echo "--- Setting Minikube profile to sbomer ---"
minikube profile sbomer

echo "--- Extracting generic Task resource from helm template ---"
mkdir -p "$OUTPUT_DIR"

  helm template local-dev "$CHART_PATH" \
      --set task.name="generator-syft" \
      --set task.agent.image="localhost/syft-agent" \
      --set task.agent.tag="latest" \
      --set task.agent.pullPolicy="Never" \
      --show-only templates/tekton/syft-generation-task.yaml \
      -f $CHART_PATH/values.yaml \
      > "$OUTPUT_FILE"

echo "Generated: $OUTPUT_FILE"

echo "--- Applying Task for Syft generation to Minikube cluster ---"
kubectl apply -f "$OUTPUT_FILE"

echo "--- Done! Applied Syft generation Task to Minikube ---"