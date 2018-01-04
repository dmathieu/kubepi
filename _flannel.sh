#!/bin/bash -e

curl https://rawgit.com/coreos/flannel/master/Documentation/kube-flannel.yml \
  | sed "s/amd64/arm/g" \
  | sed "s/vxlan/host-gw/g" \
  > .config/kube-flannel.yml
kubectl apply -f .config/kube-flannel.yml
