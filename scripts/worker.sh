#!/bin/bash
set -euo pipefail

echo "🚀 WORKER SETUP STARTED"
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
net.ipv4.ip_forward=1
EOF

sysctl --system

echo "✅ STEP 1 completed"
echo

#--------------------------------------------------
# STEP 2 — Container Runtime (CRITICAL FIX)
#--------------------------------------------------
echo "🔹 STEP 2: Installing container runtime"

apt install -y containerd docker.io curl netcat-openbsd

mkdir -p /etc/containerd
containerd config default >/etc/containerd/config.toml || true

# 🔥 MUST for Kubernetes stability
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
# STEP 4 — Wait for Master API
#--------------------------------------------------
MASTER_IP="${MASTER_IP}"

echo "🔹 STEP 4: Waiting for master API at $MASTER_IP..."

until nc -z $MASTER_IP 6443; do
  echo "⏳ Master API not ready... retrying in 5s"
  sleep 5
done

echo "✅ Master API is reachable"
echo

#--------------------------------------------------
# STEP 5 — Fetch Join Command
#--------------------------------------------------
echo "🔹 STEP 5: Fetching join command"

until curl -sf http://$MASTER_IP:8080/join.sh -o /tmp/join.sh; do
  echo "⏳ join.sh not available yet... retrying in 5s"
  sleep 5
done

chmod +x /tmp/join.sh

echo "✅ Join command fetched"
echo

#--------------------------------------------------
# STEP 6 — Join Cluster (SAFE RETRY)
#--------------------------------------------------
echo "🔹 STEP 6: Joining Kubernetes cluster"

# retry join (very important in automation)
until bash /tmp/join.sh; do
  echo "⏳ Join failed, retrying in 10s..."
  sleep 10
done

echo "✅ Worker joined cluster"
echo

#--------------------------------------------------
# STEP 7 — Wait for Node Ready
#--------------------------------------------------
echo "🔹 STEP 7: Waiting for node to become Ready"

NODE_NAME=$(hostname)

until kubectl get nodes 2>/dev/null | grep "$NODE_NAME" | grep -i ready; do
  echo "⏳ Node not ready yet..."
  sleep 5
done

echo "🎉 WORKER READY 🚀"
echo "======================================="
