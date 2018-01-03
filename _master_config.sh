#!/bin/bash -e

user=$1
address=$2

if [ -f .config/ca.csr ]; then
  echo "Certificate Authority already generated"
else
  cfssl gencert -initca data/ca-csr.json | cfssljson -bare .config/ca
fi

if [ -f .config/admin.pem ]; then
  echo "Admin certificate already generated"
else
  cfssl gencert \
    -ca=.config/ca.pem \
    -ca-key=.config/ca-key.pem \
    -config=data/ca-config.json \
    -profile=kubernetes \
    data/admin-csr.json | cfssljson -bare .config/admin
fi

if [ -f .config/master.pem ]; then
  echo "Master certificate already generated"
else
  cfssl gencert \
    -ca=.config/ca.pem \
    -ca-key=.config/ca-key.pem \
    -config=data/ca-config.json \
    -hostname=10.0.0.1,$address,127.0.0.1,kubernetes.default \
    -profile=kubernetes \
    data/master-csr.json | cfssljson -bare .config/master
fi

scp .config/ca.pem .config/ca-key.pem .config/master-key.pem .config/master.pem data/encryption-config.yaml $user@$address:~/
