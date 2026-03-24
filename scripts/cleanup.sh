#!/bin/bash

set -e

echo "=========================================="
echo "Cleanup started"
echo "=========================================="

echo "Stopping any port forwarding..."
pkill -f "port-forward" || true

if kind get clusters | grep -q "^perf-a-project$"; then
    echo "Removing Kind cluster: perf-a-project"
    echo "  (This removes all namespaces: monitoring, grafana-agent, default)"
    kind delete cluster --name perf-a-project
else
    echo "Cluster 'perf-a-project' does not exist."
fi

echo "Cleaning up kubeconfig entries..."
kubectl config unset contexts.kind-perf-a-project 2>/dev/null || true
kubectl config unset clusters.kind-perf-a-project 2>/dev/null || true
kubectl config unset users.kind-perf-a-project 2>/dev/null || true

echo "Cleaning up podman volumes..."
podman volume prune -f || true

echo "Stopping podman machine..."
podman machine stop || true
podman machine rm  || true

echo "=========================================="
echo "Cleanup completed!"
echo "=========================================="
echo "To start fresh, run: ./scripts/setup.sh"
echo "=========================================="