#!/usr/bin/env bash

KEYPAIR_NAME=${KEYPAIR_NAME:=${USER}}
keypair="${KEYPAIR_NAME}"
if [ "${KEYPAIR_NAME}" = "${USER}" ]; then
  publickeyfile="${HOME}/.ssh/id_rsa.pub"
else
  publickeyfile="${HOME}/.ssh/${KEYPAIR_NAME}.pub"
fi
regions=$(ec2-describe-regions -O "${AWS_ACCESS_KEY}" -W "${AWS_SECRET_KEY}" | cut -f2)

for region in ${regions}; do
  echo "${region}"
  ec2-import-keypair -O "${AWS_ACCESS_KEY}" -W "${AWS_SECRET_KEY}" --region "${region}" --public-key-file "${publickeyfile}" "${keypair}"
done
