#!/bin/bash
#
# More information:
# - https://scotthelme.co.uk/hpkp-http-public-key-pinning/
# - https://ithenrik.com/blog/posts/activating-http-public-key-pinning-hpkp-on-lets-encrypt

DOMAIN=$1

# check if keys are already present in current directory
if [ ! -f "${DOMAIN}.rsa.key" ]; then
    openssl req \ 
        -nodes \
        -sha256 \
        -newkey rsa:4096 \
        -keyout "${DOMAIN}.rsa.key" \
        -out "${DOMAIN}.rsa.csr" \
        -subj "/C=NL/ST=Gelderland/L=Nijmegen/O=SP2.io/OU=IT/CN=$DOMAIN/emailAddress=none@sp2.io"
    chmod 0600 ${DOMAIN}.rsa.key
fi

if [ ! -f "${DOMAIN}.ed.csr" ]; then
    openssl req \
        -nodes \
        -newkey ec:<(openssl ecparam -name prime256v1) \
        -keyout "${DOMAIN}.ec.key" \
        -out "${DOMAIN}.ec.csr" \
        -subj "/C=NL/ST=Gelderland/L=Nijmegen/O=SP2.io/OU=IT/CN=$DOMAIN/emailAddress=none@sp2.io"
    chmod 0600 ${DOMAIN}.ec.key
fi

# Create hashes for 
HASH1=$(openssl req -pubkey < $DOMAIN.rsa.csr | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64)
HASH2=$(openssl req -pubkey < $DOMAIN.ec.csr | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64)

# Create hashes for LetsEncrypts CA certs...
HASH3=$(curl -s -q https://letsencrypt.org/certs/lets-encrypt-x4-cross-signed.pem | openssl x509 -pubkey | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64)
HASH4=$(curl -s -q https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem | openssl x509 -pubkey | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64)

# and for their public root cert, aswel
HASH5=$(curl -s -q https://letsencrypt.org/certs/isrgrootx1.pem | openssl x509 -pubkey | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64)

# Echo out
echo "add_header Public-Key-Pins 'pin-sha256=\"$HASH1\"; pin-sha256=\"$HASH2\"; pin-sha256=\"$HASH3\"; pin-sha256=\"$HASH4\"; pin-sha256=\"$HASH5\"; max-age=60;';"
