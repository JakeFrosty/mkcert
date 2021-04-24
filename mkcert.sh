#!/bin/bash
# Script by JakeFrostyYT

# Variable declarations part


# Set Domain if you want to use script for renewals
# DOMAIN=yourdomainhere

# Certificate Authority files location
# Example: /root/certs/ca
CADIR=/root/certs/ca

# Validity duration of certificate
DAYS=3650

# Certificate key length
KEYLENGTH=2048

# set first argument as domain
DOMAIN=$1

# Your information here
CN=$DOMAIN
OU="Organizational Unit"
O="Organization"


if [[ $EUID -ne 0 ]]; then
	echo "Please run this as root"
	exit 1
fi

display_help() {
	echo "Usage ./mkcert.sh DOMAIN [arguments]"
	echo " -h, --help	shows this screen, arguments are found here"
	echo
	echo
	echo "Your ca certificate and ca key must be named ca.crt and ca.key"
	echo
	echo
	echo "Please note that variables must be set manually"
	echo "Variables in script:"
	echo "CADIR - Certificate authroity location"
	echo "DOMAIN - optional, if you want to use this script to renew your script then you can use this variable"
	echo "DAYS - sets how many days you want the certificate to be valid, set to 10 years by default"
	echo "KEYLENGTH - sets certificate key length"
}

exit_help() {
	display_help
	echo "Error:$1"
	exit 1
}

if [ $# -eq 0 ]; then
  display_help
  exit 0
fi

while getopts ":h" option; do
   case $option in
      h) # display Help
         display_help
         exit;;
   esac
done

if [ -d "$DOMAIN" ]; then
	echo "Directory exists, please try again or enable overwrite in script"
else
	echo "Creating directory $DOMAIN"
	mkdir $DOMAIN
fi

cd $DOMAIN

echo "Creating Key"
openssl genrsa -out $DOMAIN.key $KEYLENGTH
echo "Creating csr"
openssl req -new -key $DOMAIN.key -subj "/O=$O/OU=$OU/CN=$CN" -out $DOMAIN.csr

echo "Creating ext"
cat > $DOMAIN.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = $DOMAIN
EOF

echo "Creating certificate"
openssl x509 -req -in $DOMAIN.csr -CA $CADIR/ca.crt -CAkey $CADIR/ca.key -CAcreateserial \
-out $DOMAIN.crt -days $DAYS -sha256 -extfile $DOMAIN.ext
