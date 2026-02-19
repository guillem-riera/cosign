.PHONY: build-image

## Image configuration
# Note: Minikube now uses port 32775 for the local registry, as Apple took over port 5000 for the AirPlay functionality (2023), while Kubernetes uses port 5000. Adjust as needed.
# TODO: Find the right port, it is random
LOCAL_IMAGE_REGISTRY ?= localhost:32780
IMAGE_REGISTRY ?= localhost:5000
IMAGE_NAME ?= custom-nginx
IMAGE_VERSION ?= 1.0.0

COSIGN_LOCAL_KEY ?= cosign.key
COSIGN_LOCAL_PUBLIC_KEY ?= cosign.pub

## Generate secrets and keys if they don't exist

.secrets/cosign_password.sh:
	$(shell echo "export COSIGN_PASSWORD=$$(uuidgen)" > .secrets/cosign_password.sh)

$(COSIGN_LOCAL_KEY) $(COSIGN_LOCAL_PUBLIC_KEY): .secrets/cosign_password.sh
	source .secrets/cosign_password.sh && cosign generate-key-pair

cosign-generate-local-keys: $(COSIGN_LOCAL_KEY) $(COSIGN_LOCAL_PUBLIC_KEY)


## Build Docker image

build-image:
	docker build -t $(LOCAL_IMAGE_REGISTRY)/$(IMAGE_NAME):$(IMAGE_VERSION) .

push-image-local: build-image
	docker push $(LOCAL_IMAGE_REGISTRY)/$(IMAGE_NAME):$(IMAGE_VERSION)

# Get the image digest after pushing to the local registry, which is needed for signing and verification with Cosign.
# Keep the digest in-memory during the make invocation (no file written).

## Helper functions
define get_image_digest
$(shell docker inspect --format='{{index .RepoDigests 0}}' $(LOCAL_IMAGE_REGISTRY)/$(IMAGE_NAME):$(IMAGE_VERSION))
endef

get-image-digest:
	docker pull $(LOCAL_IMAGE_REGISTRY)/$(IMAGE_NAME):$(IMAGE_VERSION)
	@digest=$(call get_image_digest); \
	 printf "IMAGE_DIGEST=%s\n" $$digest

sign-image-local: push-image-local cosign-generate-local-keys get-image-digest
	@digest=$(call get_image_digest); \
	 source .secrets/cosign_password.sh && cosign sign --key $(COSIGN_LOCAL_KEY) $$digest

## Demo: push an unsigned image to the local registry (for testing the cluster policy)
push-unsigned-image-local:
	docker build -t $(LOCAL_IMAGE_REGISTRY)/$(IMAGE_NAME):unsigned .
	docker push $(LOCAL_IMAGE_REGISTRY)/$(IMAGE_NAME):unsigned

## Kubernetes Cluster Policy

### Cluster Policy file is located in ${CLUSTER_POLICY_FILE_TEMPLATE}, which needs to be patched with the correct image registry and public key.
### The keys to patch are: spec.rules.[0].verifyImages.[0].imageReferences.[0]
### and
### spec.rules.[0].verifyImages.[0].attestors.[0].entries.[0].keys.publicKeys (which is the public key generated locally with cosign)
CLUSTER_POLICY_FILE_TEMPLATE ?= kubernetes/manifests/cluster-policy-kyverno-no-unsigned-images.template.yaml
CLUSTER_POLICY_FILE ?= kubernetes/manifests/cluster-policy-kyverno-no-unsigned-images.yaml

generate-cluster-policy:
	@echo "Generating Cluster Policy from template..."
	export IMAGE_REGISTRY=$(IMAGE_REGISTRY) && \
	export IMAGE_NAME=$(IMAGE_NAME) && \
	export COSIGN_LOCAL_PUBLIC_KEY_DATA=$$(cat $(COSIGN_LOCAL_PUBLIC_KEY)) && \
	kubernetes/generate_cluster_policy.sh

apply-cluster-policy: generate-cluster-policy
	kubectl apply -f $(CLUSTER_POLICY_FILE)

## Cleanup local secrets

clean_local_password:
	rm -f .secrets/cosign_password.sh

clean_local_keys:
	rm -f $(COSIGN_LOCAL_KEY) $(COSIGN_LOCAL_PUBLIC_KEY)

clean_local: clean_local_password clean_local_keys
