#!/usr/bin/env bash

# Wait for Minikube to be ready
until minikube status --format '{{.Host}}' | grep -q "Running"; do
  echo "[Info] Waiting for Minikube to be ready..."
  sleep 5
done
