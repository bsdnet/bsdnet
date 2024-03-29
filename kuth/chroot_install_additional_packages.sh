#!/bin/bash

set -x
set -e

# Install additional packages
apt-get install -y           \
  apt-transport-https        \
  software-properties-common \
  gnupg2                     \
  curl                       \
  bridge-utils               \
  dnsutils                   \
  less                       \
  tmux                       \
  vim                        \
  dnsmasq                    \
  haproxy                    \
  keepalived                 \
  avahi-daemon               \
  avahi-utils
