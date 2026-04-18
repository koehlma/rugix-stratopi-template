# Rugix Strato Pi Template

Rugix Bakery template for the [Strato Pi Max](https://sferalabs.cc/strato-pi-max/)
family of edge servers. Builds ready-to-flash images with over-the-air update
support via [Rugix](https://rugix.org).

> [!WARNING]
> This project is **experimental and under active development**.

## System Images

The template provides two system image types targeting different update
strategies. Both share a common base layer with the Strato Pi Max kernel module,
RTC driver, watchdog, and device normalization recipes.

### Tryboot (single boot medium)

Uses the Raspberry Pi tryboot mechanism for A/B updates on a single boot medium
(SD card, eMMC, or NVMe SSD). The secondary SD card slot or an attached SSD can
be used for persistent data.

This is the simpler setup and works with any Strato Pi Max variant (XS or XL).
The MCU watchdog provides recovery: if an update fails to boot and send
heartbeats, the watchdog triggers a power cycle and the tryboot mechanism rolls
back to the previous system.

### Dual SD Card

Leverages the Strato Pi Max XL's dual SD card switching matrix for full A/B
redundancy. Each SD card holds a complete system. The MCU controls which card is
routed to the CM at boot, and the custom boot flow controller talks to the MCU
to coordinate updates and rollbacks.

On update, the new image is written to the inactive SD card. The boot flow
arms the watchdog for rollback, switches the SD routing, and triggers a power
cycle. If the new system boots successfully and commits, the switch is permanent.
If the watchdog expires, the MCU automatically reverts to the previous card.

This setup requires the `stratopi-dual-sd-boot` recipe and uses a custom Rugix
system configuration with `boot-flow.type = "custom"`.

## Recipes

### stratopi-max-kernel-module

Builds and installs the
[strato-pi-max-kernel-module](https://github.com/sfera-labs/strato-pi-max-kernel-module)
from source. Compiles the kernel module for each installed kernel, compiles the
device tree overlay for the selected variant, installs udev rules, and enables
module autoloading.

Parameters:

- `repo`: kernel module git repository (default: sfera-labs GitHub)
- `variant`: device tree variant, `cm4` or `cm5` (default: `cm4`)

The device tree overlay and config.txt patch are written to
`${RUGIX_LAYER_DIR}/roots/boot/` so they end up on the actual boot partition.

### stratopi-rtc

Builds and installs the [PCF2131 RTC driver](https://github.com/sfera-labs/rtc-pcf2131)
for the Strato Pi Max's on-board real-time clock. Compiles the kernel module and
device tree overlay, and patches config.txt on the boot partition.

Parameters:

- `repo`: RTC driver git repository (default: sfera-labs GitHub)
- `branch`: git branch to build from (default: `rpi-6.6.y`)

### stratopi-watchdog

Configures the Strato Pi MCU hardware watchdog and runs a periodic heartbeat.
At boot, a systemd service writes the watchdog parameters to the MCU via sysfs,
then a timer kicks the heartbeat every 5 seconds.

Parameters:

- `enabled_config`: auto-enable watchdog at power-up, `0` or `1` (default: `1`)
- `timeout_config`: heartbeat timeout in seconds (default: `60`)
- `down_delay_config`: delay before power cycle after timeout expiry, in seconds
  (default: `60`, minimum: `60`)

**Warning:** Setting `down_delay_config` below 60 seconds can brick the board.
If `enabled_config=1` and the down delay is shorter than the boot time, the MCU
will power-cycle the CM before it can start the heartbeat, creating an
unrecoverable loop. The recipe enforces a minimum of 60 seconds at both build
time and boot time.

### stratopi-power-cycle-reboot

Installs a helper script at `/usr/lib/stratopi/power-cycle-reboot` that triggers
a full power cycle of the CM through the MCU. The script syncs filesystems,
tells the MCU to initiate a power-down, and then shuts down the OS.

### stratopi-normalized-devices

Creates `/dev/stratopi/sda`, `/dev/stratopi/sdb` and partition symlinks
(`sda1`, `sda2`, `sdb1`, `sdb2`, ...) that map the Strato Pi's SD card slots to
their actual block devices. The mapping is derived from the MCU's SD routing
sysfs and the root filesystem's block device.

A systemd service creates the symlinks at boot, and a udev rule re-triggers it
whenever mmcblk devices are added, removed, or repartitioned. The script also
ensures both SD interfaces are enabled in the MCU (runtime and persistent
config).

### stratopi-dual-sd-boot

Custom Rugix boot flow for A/B updates across two SD cards. Installs the boot
flow controller script and a Rugix system configuration (`/etc/rugix/system.toml`)
that defines two boot groups (a and b), each mapping to one physical SD card
slot via the normalized device symlinks.

The boot flow controller communicates with the MCU via sysfs to:

- Query and set the active SD card routing
- Arm the watchdog for rollback on update
- Trigger MCU power cycles to switch cards
- Commit successful boots by disarming the watchdog

Depends on `stratopi-normalized-devices`.

## Building

```
./run-bakery bake <system>
```

The built image will be in `build/`.
