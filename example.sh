#!/bin/bash

./install.sh

kubectl apply -f ./examples/create-cert.yaml

kubectl certificate approve example-cert

sleep 60s

kubectl get csr example-cert -o yaml
