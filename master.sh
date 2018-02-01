#!/bin/bash -e

host="kubemaster"
address=$1

./_setup.sh $USER $address

ssh $USER@$address << EOF
if [[ \$(sudo grep "$host" /etc/hostname) ]] ; then
  echo "Hostname already configured"
else
  echo "Running apt-get update"
  sudo apt-get update
  sudo apt-get install -y policykit-1

  echo "Setting hostname to $host"
  sudo hostname $host
  sudo sh -c 'echo $host > /etc/hostname'
  sudo sh -c 'echo "127.0.1.1 $host" >> /etc/hosts'
fi
EOF

./_wifi.sh $USER $address
./_network.sh $USER $address

./_kube.sh $USER $address

ssh $USER@$address << EOF
if [[ \$(ifconfig | grep 10.0.0.1) ]] ; then
  if [ -f /etc/kubernetes/kubelet.conf ]; then
    echo "Kubeadm already initialized. Nothing to do"
  else
    echo "Initializing kubeadm"
    sudo kubeadm init \
      --pod-network-cidr 10.244.0.0/16 \
      --apiserver-advertise-address 10.0.0.1 \
      --apiserver-cert-extra-sans $address
    mkdir ~/pki
    sudo cp /etc/kubernetes/pki/* ~/pki
    sudo chown $USER ~/pki/*
  fi

else
  echo "Change to the permanent network and reboot the machine"
fi
EOF

rm -rf .config/pki
scp -r $USER@$address:pki/ .config/pki

kubectl config set-cluster raspberry \
  --server=https://$address:6443 \
  --certificate-authority=./.config/pki/ca.crt \
  --embed-certs=true
kubectl config set-credentials raspberry \
  --client-certificate=./.config/pki/apiserver-kubelet-client.crt \
  --client-key=./.config/pki/apiserver-kubelet-client.key \
  --embed-certs=true
kubectl config set-context raspberry \
  --cluster=raspberry \
  --user=raspberry
kubectl config use-context raspberry
kubectl apply -f manifests/flannel.yml
