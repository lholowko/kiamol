#!/bin/sh

echo ----------------
echo "Generating certs - hostname: $HOST_NAME; IP: $HOST_IP; SAN: $SAN, expiry days: $EXPIRY_DAYS"
echo ----------------

openssl rand -base64 32 > ca.password

openssl genrsa -aes256 -passout file:ca.password -out ca-key.pem 4096
openssl req -subj "/C=UK/ST=LONDON/L=London/O=KIAMOL/OU=elton" -new -x509 -days $EXPIRY_DAYS -passin file:ca.password -key ca-key.pem -sha256 -out ca.pem

openssl genrsa -out server-key.pem 4096
openssl req -subj "/CN=$HOST_NAME" -sha256 -new -key server-key.pem -out server.csr

echo "subjectAltName = $SAN" >> extfile.cnf
echo extendedKeyUsage = serverAuth >> extfile.cnf
openssl x509 -req -days $EXPIRY_DAYS -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem -extfile extfile.cnf -passin file:ca.password

rm *.cnf
rm *.csr
rm *.srl

echo ----------------
echo Certs generated. 
echo ----------------

# set up access to Kube API
kubectl config set-cluster default --server=https://kubernetes.default --certificate-authority=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
kubectl config set-context default --cluster=default
kubectl config set-credentials user --token=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
kubectl config set-context default --user=user
kubectl config use-context default

while true; do sleep 1000; done