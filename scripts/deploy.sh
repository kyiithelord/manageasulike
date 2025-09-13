#!/bin/bash

# Deploy Odoo to Kubernetes
# Usage: ./deploy.sh [environment]

set -e

ENVIRONMENT=${1:-"production"}
NAMESPACE="odoo"

echo "Deploying Odoo to $ENVIRONMENT environment..."

# Create namespace
kubectl apply -f k8s/namespace.yaml

# Apply secrets (make sure to update with your actual values)
kubectl apply -f k8s/secrets.yaml

# Apply ConfigMap
kubectl apply -f k8s/configmap.yaml

# Deploy PostgreSQL
kubectl apply -f k8s/postgres.yaml

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/postgres -n $NAMESPACE

# Deploy Odoo
kubectl apply -f k8s/odoo.yaml

# Deploy HPA
kubectl apply -f k8s/hpa.yaml

# Deploy Ingress
kubectl apply -f k8s/ingress.yaml

# Deploy backup CronJob
kubectl apply -f k8s/backup-cronjob.yaml

# Deploy monitoring (if Prometheus is installed)
kubectl apply -f k8s/monitoring.yaml

echo "Deployment completed!"
echo "Check the status with: kubectl get pods -n $NAMESPACE"
echo "Check services with: kubectl get svc -n $NAMESPACE"
echo "Check ingress with: kubectl get ingress -n $NAMESPACE"
