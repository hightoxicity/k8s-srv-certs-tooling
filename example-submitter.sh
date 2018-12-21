#!/bin/bash

./install.sh

kubectl apply -f ./examples/create-cert-submitter.yaml

sleep 20s

kubectl certificate approve example-cert-submitter

kubectl get csr example-cert-submitter -o yaml
