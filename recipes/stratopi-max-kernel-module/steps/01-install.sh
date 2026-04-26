#!/bin/bash

set -euo pipefail

SRC_DIR="/tmp/strato-pi-max-kernel-module"

BUILD_DEPS="build-essential device-tree-compiler"

# Record which build dependencies are already installed so we don't remove them later.
ALREADY_INSTALLED=()
for pkg in $BUILD_DEPS; do
    if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
        ALREADY_INSTALLED+=("$pkg")
    fi
done

apt-get install -y $BUILD_DEPS

# Build the kernel module for each installed kernel.
for KVER_DIR in /lib/modules/*/; do
    KVER=$(basename "$KVER_DIR")
    KDIR="/lib/modules/$KVER/build"
    [ -d "$KDIR" ] || continue
    echo "Building stratopimax.ko for kernel ${KVER}..."
    make -C "$KDIR" M="$SRC_DIR" modules
    install -m 644 "$SRC_DIR/stratopimax.ko" "/lib/modules/$KVER/"
    depmod -a "$KVER"
    make -C "$KDIR" M="$SRC_DIR" clean
done

BOOT_DIR="${RUGIX_LAYER_DIR}/roots/boot"
mkdir -p "$BOOT_DIR/overlays"

# Compile and install both CM4 and CM5 device tree overlays. config.txt
# selects between them at boot via the [cm4]/[cm5] filter sections, so the
# same image works on both modules without picking a variant at build time.
for VARIANT in cm4 cm5; do
    DTS_FILE="$SRC_DIR/stratopimax-${VARIANT}.dts"
    if [ ! -f "$DTS_FILE" ]; then
        echo "ERROR: DTS file not found: $DTS_FILE" >&2
        echo "Available variants:" >&2
        ls "$SRC_DIR"/stratopimax-*.dts 2>/dev/null >&2 || echo "  (none)" >&2
        exit 1
    fi
    dtc -@ -Hepapr -I dts -O dtb \
        -o "$BOOT_DIR/overlays/stratopimax-${VARIANT}.dtbo" \
        "$DTS_FILE"
done

# Enable the matching device tree overlay on the boot partition. Pi config
# filters scope subsequent directives to the named module; `[all]` resets
# back to apply-to-everything for any later additions.
CONFIG="$BOOT_DIR/config.txt"
if [ ! -f "$CONFIG" ]; then
    echo "ERROR: config.txt not found at $CONFIG" >&2
    exit 1
fi
if ! grep -q "^dtoverlay=stratopimax$" "$CONFIG"; then
    cat >> "$CONFIG" <<EOF
[cm4]
dtoverlay=stratopimax-cm4
# Enable host mode on the 2711 built-in XHCI USB controller. This line
# should be removed if the legacy DWC2 controller is required (e.g. for
# USB device mode) or if USB support is not required.
otg_mode=1

[cm5]
dtoverlay=dwc2,dr_mode=host
dtoverlay=stratopimax-cm5

[all]
EOF
fi

# Install udev rules.
install -m 644 "$SRC_DIR/99-stratopimax.rules" /etc/udev/rules.d/

# Auto-load the module at boot.
echo "stratopimax" > /etc/modules-load.d/stratopimax.conf

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
