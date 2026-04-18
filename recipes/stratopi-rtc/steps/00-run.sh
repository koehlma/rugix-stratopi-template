#!/bin/bash

set -euo pipefail

mkdir -p "${RUGIX_ROOT_DIR}/tmp"
git clone --depth 1 --branch "${RECIPE_PARAM_BRANCH}" "${RECIPE_PARAM_REPO}" "${RUGIX_ROOT_DIR}/tmp/rtc-pcf2131"
