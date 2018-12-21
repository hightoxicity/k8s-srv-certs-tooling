#!/bin/bash

./install.sh

kubectl apply -f ./examples/create-cert-admin.yaml

kubectl get csr example-cert-admin -o yaml
