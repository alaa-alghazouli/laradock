#!/bin/bash

DOMAIN=$1

if [ -z "$DOMAIN" ]; then
  echo "[ERROR] Domain not specified for cert copy"
  exit 1
fi

echo "[INFO] Copying certificates for $DOMAIN"

mkdir -p /var/certs

cp /etc/letsencrypt/archive/"$DOMAIN"/cert1.pem /var/certs/"$DOMAIN"-cert1.pem
cp /etc/letsencrypt/archive/"$DOMAIN"/chain1.pem /var/certs/chain1.pem
cp /etc/letsencrypt/archive/"$DOMAIN"/fullchain1.pem /var/certs/fullchain1.pem
cp /etc/letsencrypt/archive/"$DOMAIN"/privkey1.pem /var/certs/"$DOMAIN"-privkey1.pem
