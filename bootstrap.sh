#!/bin/bash
set -e

echo "Deploying ToDo application to Kubernetes..."

echo "Creating namespace..."
kubectl apply -f namespace.yml

echo "Creating PersistentVolume..."
kubectl apply -f pv.yml

echo "Creating PersistentVolumeClaim..."
kubectl apply -f pvc.yml

echo "Creating ConfigMap..."
kubectl apply -f configmap.yml

echo "Creating Secret..."
kubectl apply -f secret.yml

echo "Creating Deployment..."
kubectl apply -f deployment.yml

# Apply Service only if service.yml exists
if [ -f "service.yml" ]; then
    echo "Creating Service..."
    kubectl apply -f service.yml
fi

echo "Deployment completed successfully."