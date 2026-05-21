#!/bin/bash

set -euo pipefail

install -D -m 755 "${RECIPE_DIR}/files/sysfs-blink.sh" /usr/local/bin/sysfs-blink.sh
install -D -m 644 "${RECIPE_DIR}/files/sysfs-blink@.service" \
    /etc/systemd/system/sysfs-blink@.service

systemctl enable "sysfs-blink@${RECIPE_PARAM_INTERVAL_MS}.service"
