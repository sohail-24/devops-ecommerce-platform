#!/bin/bash

echo "🚀 Bootstrap started"

export KUBECONFIG=/etc/kubernetes/admin.conf

apt update -y
apt install -y git

# Storage
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml

# Ingress
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

# ArgoCD
kubectl create namespace argocd || true
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

sleep 60

# Clone repo
cd /home/ubuntu
git clone https://github.com/sohail-24/devops-ecommerce-kubeadm.git

cd devops-ecommerce-kubeadm

kubectl apply -f argocd/app.yaml

echo "✅ Bootstrap completed"
