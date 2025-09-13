#!/bin/bash

# Cleanup Odoo deployment from Kubernetes
# Usage: ./cleanup.sh

set -e

NAMESPACE="odoo"

echo "Cleaning up Odoo deployment..."

# Delete all resources in the namespace
kubectl delete namespace $NAMESPACE

echo "Cleanup completed!"
echo "Note: Persistent volumes are not deleted by default to preserve data."
echo "To delete persistent volumes, run: kubectl delete pv <pv-name>"
