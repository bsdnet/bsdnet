#!/bin/bash

KUBEADM_CONFIG=https://raw.githubusercontent.com/bsdnet/kubernetes-under-the-hood/master/master/kubeadm-config.yaml

## Fetch kubeadm configuration
curl $KUBEADM_CONFIG -o kubeadm-config.yaml

sudo kubeadm init --config=kubeadm-config.yaml --upload-certs 2>&1 | tee kubeadmin.log

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl get nodes -o wide
kubectl get pods -o wide -A

CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

cilium install --version 1.15.0

cilium status --wait

kubectl get nodes -o wide
kubectl get pods -o wide -A
