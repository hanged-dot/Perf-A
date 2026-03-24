#!/bin/bash

set -ex

check_tool() {
    if ! command -v $1 &> /dev/null; then
        echo "Error: No $1. Install the tool"
        exit 1
    fi
}

check_tool kind
check_tool kubectl
check_tool helm
check_tool podman

echo "Setup podman"

if podman machine list | grep -q "Currently running"; then
    echo "Podman machine is already running"
    echo "Checking current configuration..."
    podman machine inspect | grep -E "(CPUs|Memory)" || true
else
    if ! podman machine list | grep -q "podman-machine-default"; then
        echo "Initializing podman machine..."
        podman machine init || true
    fi
    
    echo "Configuring podman machine (CPUs: 4, Memory: 6144MB)..."
    if podman machine set --cpus 4 --memory 6144 2>/dev/null; then
        echo "Configuration updated successfully"
    else
        echo "Warning: Could not update configuration (machine may be running)"
        echo "Current configuration will be used"
    fi
    
    echo "Starting podman machine..."
    podman machine start || true
fi

if ! podman machine list | grep -q "Currently running"; then
    echo "Error: Podman machine is not running"
    echo "Please run: podman machine stop && podman machine start"
    exit 1
fi

export KIND_EXPERIMENTAL_PROVIDER=podman


if [ ! -f .env ]; then
    echo "File .env not defined. Please use template .env.example to create one"
    exit 1
else
    # Source .env file safely
    set +x
    while IFS='=' read -r key value; do
        [[ $key =~ ^#.*$ ]] && continue
        [[ -z $key ]] && continue
        export "$key=$value"
    done < .env
    set -x
fi

if kind get clusters | grep -q "^perf-a-project$"; then
    echo "Cluster 'perf-a-project' exists"
    echo "Proceeding with existing one"
else
    echo "Creating kind cluster"
    kind create cluster --name perf-a-project
fi

echo "Setting kubectl context to kind-perf-a-project"
kubectl config use-context kind-perf-a-project

echo "Current context: $(kubectl config current-context)"
kubectl cluster-info

echo "Update Helm"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || echo "Prometheus repo already added"
helm repo add grafana https://grafana.github.io/helm-charts 2>/dev/null || echo "Grafana repo already added"

echo "Updating Helm repositories (this may take a moment)..."
if ! helm repo update --timeout 5m; then
    echo "Warning: Helm repo update timed out or failed"
    echo "Continuing with cached repository data..."
    echo "If installation fails, check your internet connection and try again"
fi

echo "Install Prometheus..."

helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
    --namespace monitoring --create-namespace \
    --set grafana.enabled=false \
    --set alertmanager.enabled=true \
    --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
    --wait --timeout=10m

echo "Apply microservice"
kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/main/release/kubernetes-manifests.yaml

echo "Waiting for Prometheus to be ready..."
kubectl wait --for=condition=ready --timeout=300s pod -l app.kubernetes.io/name=prometheus -n monitoring

echo ""
echo "=========================================="
echo "Grafana Agent Setup"
echo "=========================================="

if [ -z "$GRAFANA_CLOUD_PROMETHEUS_URL" ] || [ -z "$GRAFANA_CLOUD_PROMETHEUS_USERNAME" ] || [ -z "$GRAFANA_CLOUD_PROMETHEUS_PASSWORD" ]; then
    echo ""
    echo "⚠ Grafana Cloud Prometheus credentials not found in .env"
    echo ""
    echo "To connect to Grafana Cloud and use Grafana Assistant:"
    echo ""
    echo "1. Get credentials from Grafana Cloud:"
    echo "   - Go to your Grafana Cloud instance"
    echo "   - Navigate to: Connections → Hosted Prometheus metrics"
    echo "   - Copy: Remote Write URL, Username, and create API token"
    echo ""
    echo "2. Add to .env file:"
    echo "   GRAFANA_CLOUD_PROMETHEUS_URL=https://prometheus-prod-xx-xxx.grafana.net/api/prom/push"
    echo "   GRAFANA_CLOUD_PROMETHEUS_USERNAME=your_instance_id"
    echo "   GRAFANA_CLOUD_PROMETHEUS_PASSWORD=your_metrics_token"
    echo ""
    echo "3. Run this script again to deploy Grafana Agent"
    echo ""
    echo "See docs/QUICK_START_HYBRID.md for detailed instructions"
    echo ""
else
    echo "✓ Grafana Cloud Prometheus credentials found"
    echo "  URL: $GRAFANA_CLOUD_PROMETHEUS_URL"
    echo "  Username: $GRAFANA_CLOUD_PROMETHEUS_USERNAME"
    echo ""
    echo "Deploying Grafana Agent..."
    
    # Create namespace
    kubectl create namespace grafana-agent --dry-run=client -o yaml | kubectl apply -f -
    
    # Create secret
    kubectl create secret generic grafana-cloud-credentials \
        --from-literal=username="$GRAFANA_CLOUD_PROMETHEUS_USERNAME" \
        --from-literal=password="$GRAFANA_CLOUD_PROMETHEUS_PASSWORD" \
        --namespace=grafana-agent \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Create ConfigMap
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-agent-config
  namespace: grafana-agent
data:
  agent.yaml: |
    server:
      log_level: info
    
    metrics:
      global:
        scrape_interval: 60s
        remote_write:
          - url: ${GRAFANA_CLOUD_PROMETHEUS_URL}
            basic_auth:
              username: ${GRAFANA_CLOUD_PROMETHEUS_USERNAME}
              password: ${GRAFANA_CLOUD_PROMETHEUS_PASSWORD}
      
      configs:
        - name: default
          scrape_configs:
            - job_name: 'federate'
              honor_labels: true
              metrics_path: '/federate'
              params:
                'match[]':
                  - '{__name__=~".+"}'
              static_configs:
                - targets:
                    - 'monitoring-kube-prometheus-prometheus.monitoring.svc.cluster.local:9090'
EOF
    
    # Deploy Grafana Agent
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana-agent
  namespace: grafana-agent
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana-agent
  template:
    metadata:
      labels:
        app: grafana-agent
    spec:
      containers:
        - name: grafana-agent
          image: grafana/agent:latest
          args:
            - -config.file=/etc/agent/agent.yaml
            - -server.http.address=0.0.0.0:12345
          ports:
            - containerPort: 12345
              name: http-metrics
          volumeMounts:
            - name: config
              mountPath: /etc/agent
      volumes:
        - name: config
          configMap:
            name: grafana-agent-config
EOF
    
    echo "Waiting for Grafana Agent to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/grafana-agent -n grafana-agent
    
    echo "✓ Grafana Agent deployed successfully"
fi

# Final summary
echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "✓ KIND cluster: perf-a-project"
echo "✓ Prometheus: monitoring namespace"
echo "✓ Microservices: default namespace"

if [ ! -z "$GRAFANA_CLOUD_PROMETHEUS_URL" ]; then
    echo "✓ Grafana Agent: pushing metrics to Grafana Cloud"
    echo ""
    echo "Next steps:"
    echo "1. Go to your Grafana Cloud instance"
    echo "2. Click Explore (compass icon)"
    echo "3. Query: up"
    echo "4. Use Grafana Assistant (AI icon ✨)"
    echo ""
    echo "See docs/GRAFANA_CLOUD_USAGE_GUIDE.md for detailed usage instructions"
else
    echo "⚠ Grafana Agent: not deployed (missing credentials)"
    echo ""
    echo "To enable Grafana Cloud integration:"
    echo "1. Add Prometheus credentials to .env file"
    echo "2. Run: ./scripts/setup.sh again"
    echo ""
    echo "See docs/QUICK_START_HYBRID.md for setup instructions"
fi

echo ""
echo "Useful commands:"
echo "  - Check all pods: kubectl get pods -A"
echo "  - Check Prometheus: kubectl get pods -n monitoring"
echo "  - Check microservices: kubectl get pods -n default"
if [ ! -z "$GRAFANA_CLOUD_PROMETHEUS_URL" ]; then
    echo "  - Check Grafana Agent: kubectl get pods -n grafana-agent"
    echo "  - View agent logs: kubectl logs -n grafana-agent deployment/grafana-agent -f"
fi
echo "  - Cleanup everything: ./scripts/cleanup.sh"
echo "=========================================="