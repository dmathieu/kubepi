#!/bin/bash -e

masterHost="kubemaster"
host=$1
address=$2
isIngress=0

while (( $# > 0 ))
do
  case "$1" in
    (--ingress)
      isIngress=1
      ;;
    (*)
      ;;
  esac
  shift
done

./_setup.sh $USER $address

if [ $isIngress == 1 ]; then
  ./_wifi.sh $USER $address
fi

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
  sudo sh -c 'echo "10.0.0.1 $masterHost" >> /etc/hosts'
fi
EOF

./_kube.sh $USER $address

kubectl config use-context raspberry
kubectl config set-cluster master \
  --kubeconfig=.config/node.conf \
  --server=https://10.0.0.1:6443 \
  --certificate-authority=./.config/pki/ca.crt \
  --embed-certs=true
kubectl config set-context master \
  --kubeconfig=.config/node.conf \
  --cluster=master
kubectl config use-context master --kubeconfig=.config/node.conf

scp .config/node.conf $USER@$address:node.conf

secret=`kubectl get secrets \
  --namespace kube-system \
  --field-selector="type=bootstrap.kubernetes.io/token" \
  -o json`
l=`echo $secret | jq '.items[0] | .data'`
if [[ $l == "null" ]] ; then
  echo "No token. Creating one"
  token=$(ssh $USER@10.0.0.1 sudo kubeadm token create)
else
  tokenId=`echo $secret | jq --raw-output '.items[0] | .data | .["token-id"]' | base64 --decode`
  tokenSecret=`echo $secret | jq --raw-output '.items[0] | .data | .["token-secret"]' | base64 --decode`
  token="$tokenId.$tokenSecret"
fi

ssh $USER@$address << EOF
  if [ -f /etc/kubernetes/kubelet.conf ]; then
    echo "Node already joined. Nothing to do"
  else
    sudo kubeadm join --token $token --discovery-file node.conf
  fi
EOF

if [ $isIngress == 1 ]; then
  ./_ingress.sh $USER $address $host
fi
