#!/bin/bash

kubectl apply -f ./k8s-defs/service-account/server-certs-submitter.yaml
kubectl apply -f ./k8s-defs/cluster-role/kube-system-csr-submitter.yaml
kubectl apply -f ./k8s-defs/role/kube-system-secrets-manager.yaml
kubectl apply -f ./k8s-defs/role-binding/kube-system-server-certs-submitter-secret-manager.yaml
kubectl apply -f ./k8s-defs/cluster-role-binding/kube-system-server-certs-submitter-submit-csr.yaml
