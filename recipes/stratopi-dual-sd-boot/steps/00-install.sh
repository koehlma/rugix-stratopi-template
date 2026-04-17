#!/bin/bash

set -euo pipefail

mkdir -p /usr/lib/stratopi
install -m 755 "${RECIPE_DIR}/files/boot-flow" /usr/lib/stratopi/

mkdir -p /etc/rugix
install -m 644 "${RECIPE_DIR}/files/system.toml" /etc/rugix/system.toml
