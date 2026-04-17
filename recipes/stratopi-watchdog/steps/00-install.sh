#!/bin/bash

set -euo pipefail

if [[ "${RECIPE_PARAM_DOWN_DELAY_CONFIG}" -lt 60 ]]; then
    echo "ERROR: down_delay_config must be at least 60s to avoid bricking the board" >&2
    exit 1
fi

mkdir -p /usr/lib/stratopi
install -m 755 "${RECIPE_DIR}/files/configure-watchdog" /usr/lib/stratopi/

# Bake recipe parameters into the environment file read at boot.
cat > /etc/stratopi-watchdog.conf <<EOF
WATCHDOG_ENABLED_CONFIG=${RECIPE_PARAM_ENABLED_CONFIG}
WATCHDOG_TIMEOUT_CONFIG=${RECIPE_PARAM_TIMEOUT_CONFIG}
WATCHDOG_DOWN_DELAY_CONFIG=${RECIPE_PARAM_DOWN_DELAY_CONFIG}
EOF

install -m 644 "${RECIPE_DIR}/files/configure-watchdog.service" /etc/systemd/system/
install -m 644 "${RECIPE_DIR}/files/kick-watchdog.service" /etc/systemd/system/
install -m 644 "${RECIPE_DIR}/files/kick-watchdog.timer" /etc/systemd/system/
systemctl enable configure-watchdog.service
systemctl enable kick-watchdog.timer
