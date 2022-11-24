#! /bin/bash
set -ex

SCRIPTS_DIR=$(cd $(dirname "$0") && pwd -P)
ROOT=$(dirname $SCRIPTS_DIR)

if ! [ -x "$(command -v cddl)" ] || [ "$1" = "--upgrade" ]; then
  echo 'Installing cddl'
  cargo install cddl
fi

cddl compile-cddl --cddl ${ROOT}/schemas/at-driver-local.cddl
cddl compile-cddl --cddl ${ROOT}/schemas/at-driver-remote.cddl
