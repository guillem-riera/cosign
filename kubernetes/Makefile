.PHONY: start-minikube wait-for-minikube enable-registry

start-minikube:
	minikube start

wait-for-minikube:
	./wait_for_minikube.sh

enable-registry: wait-for-minikube
	minikube addons list| grep registry | grep enabled || minikube addons enable registry

install-kyverno: wait-for-minikube
	helm repo add kyverno https://kyverno.github.io/kyverno/
	helm repo update
	helm upgrade --install kyverno kyverno/kyverno -n kyverno --create-namespace

