#!/usr/bin/env bash

WORKING_DIR=$(realpath $(dirname "$0"))
CLUSTER_POLICY_FILE_TEMPLATE=${CLUSTER_POLICY_FILE_TEMPLATE:-"${WORKING_DIR}/manifests/cluster-policy-kyverno-no-unsigned-images.template.yaml"}
CLUSTER_POLICY_FILE=${CLUSTER_POLICY_FILE:-"${WORKING_DIR}/manifests/cluster-policy-kyverno-no-unsigned-images.yaml"}
export IMAGE_REGISTRY=${IMAGE_REGISTRY:-"localhost:5000"}
export IMAGE_NAME=${IMAGE_NAME:-"custom-nginx"}
export COSIGN_LOCAL_PUBLIC_KEY=${COSIGN_LOCAL_PUBLIC_KEY:-"$(realpath ${WORKING_DIR}/../cosign.pub)"}
export COSIGN_LOCAL_PUBLIC_KEY_DATA=${COSIGN_LOCAL_PUBLIC_KEY_DATA:-"$(cat ${COSIGN_LOCAL_PUBLIC_KEY})"}
export PUBLIC_KEY_INDENTATION='                      ' # Poor man's solution. For demonstration purposes only. In production, consider using a more robust templating solution.

# Create an indented version of the public key for YAML formatting
INDENTED_PUBLIC_KEY=$(echo "${COSIGN_LOCAL_PUBLIC_KEY_DATA}" | sed "s/^/${PUBLIC_KEY_INDENTATION}/")
export COSIGN_LOCAL_PUBLIC_KEY_DATA="${INDENTED_PUBLIC_KEY}"

# Generate the Cluster Policy from the template
envsubst < "${CLUSTER_POLICY_FILE_TEMPLATE}" > "${CLUSTER_POLICY_FILE}"
echo "Cluster Policy generated at: ${CLUSTER_POLICY_FILE}"
