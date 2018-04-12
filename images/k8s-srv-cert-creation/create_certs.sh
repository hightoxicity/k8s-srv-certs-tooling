#!/bin/sh
set -e
set -o pipefail

FORCE_GEN=0

if [ ! -z "${FORCE_GENERATION}" ]; then
  FORCE_GEN=${FORCE_GENERATION}
fi

if [ "${FORCE_GEN}" == "0" ]; then
  kubectl get csr ${CERT_NAME} && exit 0 || true
else
  kubectl delete csr ${CERT_NAME} || true
fi

cp /in.req /wkd

OLDIFS=${IFS}

env | while IFS='=' read -r name value ; do
  if [ "$(echo ${name} | cut -c 1-8)" = 'CERTREQ_' ]; then
    sed -i "s/\[\[${name}\]\]/${value}/g" /wkd/in.req
  fi
done

alt_names_ref=''

if [ ! -z "${CERTREQ_SAN}" ]; then
  echo "[alt_names]" >> /wkd/in.req
  IFS=','
  i=1
  for SAN in ${CERTREQ_SAN}
  do
    echo "DNS.${i} = ${SAN}" >> /wkd/in.req
    i=$((i+1))
  done
  alt_names_ref="subjectAltName         = @alt_names"
fi

sed -i "s/\[\[ALTNAMES_PLACEHOLDER\]\]/${alt_names_ref}/g" /wkd/in.req

IFS=${OLDIFS}

echo "We will use following req:"

cat /wkd/in.req

openssl genrsa -out /wkd/tls.key 4096
openssl req -new -config /wkd/in.req -key /wkd/tls.key -out /wkd/tls.csr

if [ "${alt_names_ref}" != "" ]; then
  openssl req -noout -text -in /wkd/tls.csr | grep DNS
fi

cat <<EOF | kubectl create -f -
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: ${CERT_NAME}
spec:
  groups:
  - system:serviceaccounts
  - system:serviceaccounts:kube-system
  - system:authenticated
  request: $(cat /wkd/tls.csr | base64 | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - server auth
  - client auth
EOF

echo "Cert ${CERT_NAME} csr submitted to the cluster!"

while [ "$(kubectl get csr ${CERT_NAME} -o jsonpath='{.status.conditions[:1].type}')" == "" ]; do
  sleep 60s
  echo "Csr not reviewed yet!"
done

if [ "$(kubectl get csr ${CERT_NAME} -o jsonpath='{.status.conditions[:1].type}')" == "Approved" ]; then
  echo "Csr approved, we create a matching secret..."
  kubectl get csr ${CERT_NAME} -o jsonpath='{.status.certificate}' | base64 -d > /wkd/tls.crt
  kubectl delete secret ${CERT_NAME} || true
  kubectl create --namespace=kube-system secret generic ${CERT_NAME} --from-file=/wkd/tls.key --from-file=/wkd/tls.crt
fi
