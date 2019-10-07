#!/bin/bash -e

user=$1
address=$2


ssh $user@$address << EOF
if ! docker -v; then
  echo "Setting up docker"
  curl -sSL https://get.docker.com | sh
  sudo usermod $user -aG docker

  echo "
{
  \"exec-opts\": [\"native.cgroupdriver=systemd\"],
  \"log-driver\": \"json-file\",
  \"log-opts\": {
    \"max-size\": \"100m\"
  },
  \"storage-driver\": \"overlay2\"
}" | sudo tee /etc/docker/daemon.json

  sudo service docker restart
fi

sudo dphys-swapfile swapoff
sudo dphys-swapfile uninstall
sudo update-rc.d dphys-swapfile remove

if ! kubeadm version; then
  echo "Setting up kubernetes"
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
  echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
  sudo apt-get update
  sudo apt-get install -y kubelet kubeadm kubectl kubernetes-cni
fi
EOF
