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
  if [ -d /etc/kubernetes/manifests ]; then
    echo "Kubeadm already initialized. Nothing to do"
  else
    echo "Initializing kubeadm"
    sudo kubeadm init
    sudo cp /etc/kubernetes/admin.conf ~/admin.conf
    sudo chown $USER admin.conf
  fi

else
  echo "Change to the permanent network and reboot the machine"
fi
EOF

scp $USER@$address:admin.conf .config/admin.conf
mv .config/admin.conf ~/.kube/raspberry
kubectl config use-context kubernetes-admin@kubernetes

./_flannel.sh
