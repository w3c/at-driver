#!/bin/bash

# Create a VirtualBox image for Windows 10 using the provided product key.

set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo A Windows product key must be provided as the first argument to this script. >&2
  exit 1
fi

# Build the "generic" virtual machine image
packer build windows_10.pkr.hcl

# Build the "customized" virtual machine image
packer build \
  --var windows_product_key=$1 \
  customized.pkr.hcl
