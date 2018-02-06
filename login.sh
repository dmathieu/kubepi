#!/bin/bash -e

address=$1

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
