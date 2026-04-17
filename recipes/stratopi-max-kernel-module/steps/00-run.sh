#!/bin/bash

set -euo pipefail

mkdir -p "${RUGIX_ROOT_DIR}/tmp"
git clone --depth 1 --recursive "${RECIPE_PARAM_REPO}" "${RUGIX_ROOT_DIR}/tmp/strato-pi-max-kernel-module"
