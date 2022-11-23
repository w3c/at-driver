#! /bin/bash
set -ex

if ! [ -x "$(command -v cddl)" ] || [ "$1" = "--upgrade" ]; then
  echo 'Installing cddl'
  cargo install cddl
fi

cddl compile-cddl --cddl schemas/at-driver-local.cddl
cddl compile-cddl --cddl schemas/at-driver-remote.cddl
