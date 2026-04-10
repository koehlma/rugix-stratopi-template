#!/bin/bash

set -euo pipefail

SRC_DIR="/tmp/strato-pi-kernel-module"

BUILD_DEPS="build-essential device-tree-compiler"

# Record which build dependencies are already installed so we don't remove them later.
ALREADY_INSTALLED=()
for pkg in $BUILD_DEPS; do
    if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
        ALREADY_INSTALLED+=("$pkg")
    fi
done

# Install build dependencies.
apt-get install -y $BUILD_DEPS

# Build the kernel module for each installed kernel.
for KVER_DIR in /lib/modules/*/; do
    KVER=$(basename "$KVER_DIR")
    KDIR="/lib/modules/$KVER/build"
    [ -d "$KDIR" ] || continue
    echo "Building stratopi.ko for kernel ${KVER}..."
    make -C "$KDIR" M="$SRC_DIR" modules
    install -m 644 "$SRC_DIR/stratopi.ko" "/lib/modules/$KVER/"
    depmod -a "$KVER"
    make -C "$KDIR" M="$SRC_DIR" clean
done

# Compile and install the device tree overlay.
mkdir -p /boot/firmware/overlays
dtc -@ -Hepapr -I dts -O dtb \
    -o /boot/firmware/overlays/stratopi.dtbo \
    "$SRC_DIR/stratopi.dts"

# Install udev rules.
install -m 644 "$SRC_DIR/99-stratopi.rules" /etc/udev/rules.d/

# Auto-load the module at boot.
echo "stratopi" > /etc/modules-load.d/stratopi.conf

# Enable the device tree overlay.
if [ -f /boot/firmware/config.txt ]; then
    echo "dtoverlay=stratopi" >> /boot/firmware/config.txt
fi

# Clean up: only remove build dependencies that were not already installed.
rm -rf "$SRC_DIR"
TO_REMOVE=()
for pkg in $BUILD_DEPS; do
    skip=false
    for kept in "${ALREADY_INSTALLED[@]}"; do
        if [ "$pkg" = "$kept" ]; then
            skip=true
            break
        fi
    done
    if [ "$skip" = false ]; then
        TO_REMOVE+=("$pkg")
    fi
done
if [ ${#TO_REMOVE[@]} -gt 0 ]; then
    apt-get purge -y "${TO_REMOVE[@]}"
    apt-get autoremove -y --purge
fi
apt-get clean
rm -rf /var/lib/apt/lists/*
