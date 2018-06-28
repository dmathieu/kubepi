#!/bin/bash -e

user=$1
address=$2

ssh $user@$address << EOF
  sudo apt-get install -y nfs-kernel-server nfs-common
  sudo systemctl enable nfs-kernel-server

  if [[ \$(sudo grep "/mnt/extusb" /etc/fstab) ]] ; then
    sudo mkdir /mnt/extusb
    sudo chown -R pi:pi /mnt/extusb
    sudo mount /dev/sda1 /mnt/extusb -o uid=$user,gid=$user
    mkdir /mnt/extusb/kube

    echo "/dev/sda1 /mnt/extusb auto defaults,user 0 1" | sudo tee -a /etc/fstab
    echo "/mnt/extusb/kube/ 10.0.0.*(rw,sync,no_subtree_check,no_root_squash)" | sudo tee /etc/exports
    sudo exportfs -a
  fi
EOF
