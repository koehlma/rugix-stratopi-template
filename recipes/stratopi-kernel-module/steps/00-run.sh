#!/bin/bash

set -euo pipefail

# Clone the kernel module source into the target rootfs so it is available
# for building inside the chroot in the next step. Using /tmp ensures it
# gets cleaned up automatically by the bakery after layer finalization.
mkdir -p "${RUGIX_ROOT_DIR}/tmp"
git clone --depth 1 --recursive "${RECIPE_PARAM_REPO}" "${RUGIX_ROOT_DIR}/tmp/strato-pi-kernel-module"
