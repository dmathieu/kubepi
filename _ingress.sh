#!/bin/bash -e

user=$1
address=$2
host=$3

wlanAddress=$(ssh $user@$address sudo ifconfig wlan0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
until kubectl get node $host; do
  echo "Waiting for node to show up in kubectl"
  sleep 1
done

if [[ ! $(grep "$wlanAddress" manifests/nginx/service.yml) ]] ; then
  echo "Adding $wlanAddress to service.yml"

  echo "  externalIPs:
  - $wlanAddress" >> manifests/nginx/service.yml
fi

kubectl label nodes $host nodeIngress=yes --overwrite
kubectl create namespace ingress-nginx || echo "Namespace already exists"
kubectl apply -f manifests/nginx/
