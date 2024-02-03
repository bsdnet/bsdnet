#!/bin/bash
set -x
set -e

KUTH_REPO_PATH=${KUTH_REPO:-$HOME/workspace/kubernetes-under-the-hood}
NUM_OF_CP_NODES=${NUM_OF_CP_NODES:-1}
CP_NODES_ARRAY=(kube-mast01 kube-mast02 kube-mast03)
NUM_OF_WORKER_NODES=${NUM_OF_WORKER_NODES:-1}
WORKER_NODES_ARRAY=(kube-node01 kube-node02 kube-node03)
CLUSTER_ROLE=Standalone # Standalone Management, User, Infrastructure
NODE_ROLE= #GATEWAY, BUSYBOX, LOAD-BALANCER, CONTROL-PLANE, WORKER, STORAGE
DEBIAN_BASE_IMAGE="debian-base-image-bookworm"

# Update the control plane node array
if [[ ${NUM_OF_CP_NODES} == 1 ]]; then
  CP_NODES_ARRAY=(kube-mast01)
fi

# Update the worker node array
if [[ ${NUM_OF_WORKER_NODES} == 1 ]]; then
  WORKER_NODES_ARRAY=(kube-node01)
fi

# Create Gateway
pushd $KUTH_REPO_PATH
./create-image.sh \
  -k ~/.ssh/id_rsa.pub \
  -u gate/user-data \
  -n gate/network-config \
  -i gate/post-config-interfaces \
  -r gate/post-config-resources \
  -o gateway \
  -l debian \
  -b ${DEBIAN_BASE_IMAGE}

# Create busybox
./create-image.sh \
  -k ~/.ssh/id_rsa.pub \
  -u busybox/user-data \
  -n busybox/network-config \
  -i busybox/post-config-interfaces \
  -r busybox/post-config-resources \
  -o busybox \
  -l debian \
  -b ${DEBIAN_BASE_IMAGE}

# Create CP nodes
for INSTANCE in ${CP_NODES_ARRAY[@]}; do
    ./create-image.sh \
        -k ~/.ssh/id_rsa.pub \
        -u kube-mast/user-data \
        -n kube-mast/network-config \
        -i kube-mast/post-config-interfaces \
        -r kube-mast/post-config-resources \
        -o ${INSTANCE} \
        -l debian \
        -b ${DEBIAN_BASE_IMAGE}
done

# Create worker node.
for INSTANCE in ${WORK_NODES_ARRAY[@]}; do
    ./create-image.sh \
        -k ~/.ssh/id_rsa.pub \
        -u kube-node/user-data \
        -n kube-node/network-config \
        -i kube-node/post-config-interfaces \
        -r kube-node/post-config-resources \
        -o ${INSTANCE} \
        -l debian \
        -b ${DEBIAN_BASE_IMAGE}
done

vboxmanage guestproperty get busybox "/VirtualBox/GuestInfo/Net/0/V4/IP"
sudo ip route add 192.168.4.32/27 via 192.168.4.62 dev vboxnet0

popd
