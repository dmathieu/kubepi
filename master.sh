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
