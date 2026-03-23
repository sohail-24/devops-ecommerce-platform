#!/bin/bash
set -euo pipefail

echo "🚀 MASTER SETUP STARTED"
echo "======================================="

#--------------------------------------------------
# STEP 1 — System Preparation
#--------------------------------------------------
echo "🔹 STEP 1: System preparation"

apt update -y && apt upgrade -y

swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

modprobe br_netfilter
echo br_netfilter >/etc/modules-load.d/br_netfilter.conf

cat <<EOF >/etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
EOF

sysctl --system

echo "✅ STEP 1 completed"
echo

#--------------------------------------------------
# STEP 2 — Container Runtime
#--------------------------------------------------
echo "🔹 STEP 2: Installing container runtime"

apt install -y containerd docker.io curl

mkdir -p /etc/containerd
containerd config default >/etc/containerd/config.toml || true

# Ensure systemd cgroup (required for kubelet compatibility)
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml || true

systemctl restart containerd
systemctl enable containerd

systemctl enable docker
systemctl start docker

echo "✅ STEP 2 completed"
echo

#--------------------------------------------------
# STEP 3 — Kubernetes Components
#--------------------------------------------------
echo "🔹 STEP 3: Installing Kubernetes components"

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | \
  gpg --dearmor --yes -o /usr/share/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" \
>/etc/apt/sources.list.d/kubernetes.list

apt update -y
apt install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

systemctl enable kubelet

echo "✅ STEP 3 completed"
echo

#--------------------------------------------------
# STEP 4 — Initialize Cluster
#--------------------------------------------------
echo "🔹 STEP 4: Initializing Kubernetes cluster"

kubeadm init --pod-network-cidr=192.168.0.0/16 | tee /root/init.log

echo "✅ kubeadm init completed"
echo

#--------------------------------------------------
# STEP 5 — Configure kubectl for ubuntu user
#--------------------------------------------------
echo "🔹 STEP 5: Configuring kubectl"

mkdir -p /home/ubuntu/.kube
cp /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config

export KUBECONFIG=/etc/kubernetes/admin.conf

echo "✅ kubectl configured"
echo

#--------------------------------------------------
# STEP 6 — Wait for API server to accept requests
#--------------------------------------------------
echo "🔹 STEP 6: Waiting for API server"

until kubectl get nodes >/dev/null 2>&1; do
  echo "⏳ API not ready yet..."
  sleep 5
done

echo "✅ API server is ready"
echo

#--------------------------------------------------
# STEP 7 — Install Calico (VERY IMPORTANT FIRST)
#--------------------------------------------------
echo "🔹 STEP 7: Installing Calico network"

kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/calico.yaml

# Wait for expected number of nodes to exist (so we know how many calico pods to expect)
NUM_NODES=0
until [ "$NUM_NODES" -ge 1 ]; do
  NUM_NODES=$(kubectl get nodes --no-headers 2>/dev/null | wc -l || echo 0)
  echo "⏳ waiting for at least 1 node to appear (found: $NUM_NODES)..."
  sleep 3
done

echo "🔹 expecting $NUM_NODES calico node pods to come up"

# Wait until calico-node daemonset has one pod per node and each is 1/1 ready
while true; do
  TOTAL_CALICO=$(kubectl get pods -n kube-system -l k8s-app=calico-node --no-headers 2>/dev/null | wc -l || echo 0)
  READY_CALICO=$(kubectl get pods -n kube-system -l k8s-app=calico-node --no-headers 2>/dev/null | awk '{print $2}' | grep -c '^1/1$' || echo 0)
  if [ "$TOTAL_CALICO" -gt 0 ] && [ "$READY_CALICO" -eq "$TOTAL_CALICO" ] && [ "$TOTAL_CALICO" -eq "$NUM_NODES" ]; then
    break
  fi
  echo "⏳ Calico pods ready: $READY_CALICO / $NUM_NODES (total found: $TOTAL_CALICO). Waiting..."
  sleep 5
done

# Force calico to use can-reach autodetection (more reliable on AWS)
kubectl set env daemonset/calico-node -n kube-system IP_AUTODETECTION_METHOD=can-reach=8.8.8.8 || true

echo "✅ Calico installed (pods running on all nodes)"
echo

#--------------------------------------------------
# STEP 8 — Wait for all nodes to be Ready
#--------------------------------------------------
echo "🔹 STEP 8: Waiting for nodes to be Ready"

# wait until every node shows Ready in the second column
while kubectl get nodes --no-headers 2>/dev/null | awk '{print $2}' | grep -qv '^Ready$'; do
  echo "⏳ Nodes not ready yet..."
  kubectl get nodes --no-headers || true
  sleep 5
done

echo "✅ All nodes are Ready"
echo

#--------------------------------------------------
# STEP 9 — Generate Join Command
#--------------------------------------------------
echo "🔹 STEP 9: Generating join command"

kubeadm token create --print-join-command > /home/ubuntu/join.sh
chmod +x /home/ubuntu/join.sh

echo "✅ Join command saved at /home/ubuntu/join.sh"
echo

#--------------------------------------------------
# STEP 9.1 — Start HTTP Server for Workers to fetch join script
#--------------------------------------------------
echo "🚀 Starting HTTP server for join.sh"

cd /home/ubuntu
nohup python3 -m http.server 8080 > /dev/null 2>&1 &

echo "✅ HTTP server started on port 8080"
echo

#--------------------------------------------------
# STEP 10 — Install ArgoCD
#--------------------------------------------------
echo "🔹 STEP 10: Installing ArgoCD"

kubectl create namespace argocd || true

kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.10.7/manifests/install.yaml

echo "⏳ Waiting for ArgoCD pods..."

# wait until all argocd pods are 1/1
while kubectl get pods -n argocd --no-headers 2>/dev/null | awk '{print $2}' | grep -qv '^1/1$'; do
  echo "⏳ ArgoCD pods not ready yet..."
  kubectl get pods -n argocd --no-headers || true
  sleep 10
done

echo "✅ ArgoCD installed"
echo

#--------------------------------------------------
# DONE
#--------------------------------------------------
echo "🎉 MASTER SETUP COMPLETE 🚀"
echo "======================================="
