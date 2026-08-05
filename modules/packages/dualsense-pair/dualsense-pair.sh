#!/usr/bin/env bash
# Remove any stale DualSense pairing, make sure Bluetooth is powered on,
# then wait for a nearby DualSense in pairing mode and pair/trust/connect.

set -euo pipefail

MAC_RE='([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}'

is_dualsense() {
	local info
	info=$(bluetoothctl info "$1" 2>/dev/null || true)
	[[ "$info" == *"Modalias: usb:v054Cp0CE6"* ]]
}

echo "removing stale DualSense pairing..."
for dev in $(bluetoothctl devices 2>/dev/null | grep -oE "$MAC_RE" || true); do
	if is_dualsense "$dev"; then
		echo "  removing $dev"
		bluetoothctl remove "$dev" >/dev/null
	fi
done

if ! bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
	echo "Bluetooth is off, powering on..."
	bluetoothctl power on >/dev/null
	sleep 1
fi

echo "starting scan..."
bluetoothctl scan on >/dev/null &
scan_pid=$!
trap 'kill "$scan_pid" 2>/dev/null || true; bluetoothctl scan off >/dev/null 2>&1 || true' EXIT

echo "put your DualSense into pairing mode (hold PS + Share)"
found=0
for _ in {1..120}; do
	for dev in $(bluetoothctl devices 2>/dev/null | grep -oE "$MAC_RE" || true); do
		if is_dualsense "$dev"; then
			found=1
			break 2
		fi
	done
	sleep 1
done

if [[ $found -eq 0 ]]; then
	echo "no DualSense found within 2 minutes"
	exit 1
fi

echo "found $dev, pairing..."
bluetoothctl pair "$dev" >/dev/null || {
	echo "pairing failed"
	exit 1
}
bluetoothctl trust "$dev" >/dev/null
echo "connecting..."
bluetoothctl connect "$dev" >/dev/null || true
echo "done: $dev"
