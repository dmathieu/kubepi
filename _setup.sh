#!/bin/bash -e

user=$1
address=$2
key=`cat ~/.ssh/id_rsa.pub`

echo "Connecting to $address"
conf=~/.ssh/known_hosts

if [[ $(grep "$address" $conf ) ]] ; then
  echo "User already configured"
else
  ssh-keyscan -t ecdsa-sha2-nistp256 $address >> $conf

  ssh pi@$address << EOF
    echo "Creating user $user"
    sudo useradd $user -d /home/$user -m -s /bin/bash
    sudo usermod -aG sudo $user
    sudo mkdir -p /home/$user/.ssh
    sudo chown -R $user /home/$user
    sudo sh -c 'echo $key > /home/$user/.ssh/authorized_keys'
    sudo sh -c 'echo "$user ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/010_$user-nopasswd'
EOF

  ssh $user@$address << EOF
    echo "Deleting user pi"
    sudo userdel -f pi
EOF
fi
