#!/bin/bash

# Create destination folder
# ~~~~~~~~~~~~~~~~~~~~~~~~~

    ssldir="/etc/ssl/zarafa"
    mkdir ${ssldir}

# Generate RootCA
# ~~~~~~~~~~~~~~~

    openssl genrsa -out ${ssldir}/ca.key 4096
    openssl req -new -x509 -days 3650 \
                -key ${ssldir}/ca.key \
                -out ${ssldir}/ca.crt \
                -subj "/C=${LB_SSL_STATE}/ST=${LB_SSL_LOCATION}/O=RootCA ${LB_SSL_COMPANY}/CN=zarafa"

# Generate a random password for
# zarafa keyfile
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    openssl rand -hex 512 | tr -d '\n' > ${ssldir}/zarafa.pass

# Generate zarafa certificate request
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    openssl genrsa -des3 -passout file:${ssldir}/zarafa.pass -out ${ssldir}/zarafa.key 4096
    openssl req -new -key ${ssldir}/zarafa.key \
                -out ${ssldir}/zarafa.csr \
                -passin file:${ssldir}/zarafa.pass \
                -subj "/C=${LB_SSL_STATE}/ST=${LB_SSL_LOCATION}/O=Application ${LB_SSL_COMPANY}/CN=zarafa"

# Sign request
# ~~~~~~~~~~~~

    openssl x509 -req -days 3650 -in ${ssldir}/zarafa.csr \
                 -CA ${ssldir}/ca.crt \
                 -CAkey ${ssldir}/ca.key \
                 -set_serial 01 \
                 -out ${ssldir}/zarafa.crt

# Zarafa specific: merge private key
# and certificate into a single file
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    cat ${ssldir}/zarafa.key ${ssldir}/zarafa.crt > ${ssldir}/zarafaserver.pem

# Apache specific: remove password
# from the key file
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    openssl rsa -in ${ssldir}/zarafa.key \
                -out ${ssldir}/zarafa.nopass.key \
                -passin file:${ssldir}/zarafa.pass

# Set correct permissions
# ~~~~~~~~~~~~~~~~~~~~~~~

    chmod -R 600 ${ssldir}
