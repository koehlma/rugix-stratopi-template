#!/bin/sh

LED_PATH="/sys/class/stratopimax/led/green"
INTERVAL_MS="${INTERVAL_MS:-500}"

while true; do
    echo 1 > "$LED_PATH"
    sleep "$(awk "BEGIN {print $INTERVAL_MS/1000}")"
    echo 0 > "$LED_PATH"
    sleep "$(awk "BEGIN {print $INTERVAL_MS/1000}")"
done
