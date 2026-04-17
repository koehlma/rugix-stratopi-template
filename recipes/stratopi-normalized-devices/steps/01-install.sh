#!/bin/bash

set -euo pipefail

mkdir -p /usr/lib/stratopi
install -m 755 "${RECIPE_DIR}/files/create-normalized-devices" /usr/lib/stratopi/

install -m 644 "${RECIPE_DIR}/files/create-normalized-devices.service" /etc/systemd/system/
install -m 644 "${RECIPE_DIR}/files/99-stratopi-normalized-devices.rules" /etc/udev/rules.d/
systemctl enable create-normalized-devices.service
