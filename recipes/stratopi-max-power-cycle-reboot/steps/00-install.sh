#!/bin/bash

set -euo pipefail

mkdir -p /usr/lib/stratopi
install -m 755 "${RECIPE_DIR}/files/power-cycle-reboot" /usr/lib/stratopi/
