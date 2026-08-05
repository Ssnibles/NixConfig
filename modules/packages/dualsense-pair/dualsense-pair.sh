#!/usr/bin/env bash
# Wake-and-connect helper for a PS5 DualSense.
#
# Usage: run this script, then just press the PS button on the controller.
# If the pad is already paired it will connect without pairing mode; if not,
# put it in pairing mode (PS + Share) and it will be paired on the spot.

set -euo pipefail

MAC_RE='([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}'
DS_MODALIAS='usb:v054Cp0CE6'

is_dualsense() {
	local mac="$1" info
	info=$(bluetoothctl info "$mac" 2>/dev/null || true)
	[[ "$info" == *"Modalias: usb:v054Cp0CE6"* ]]
}

all_macs() {
	bluetoothctl devices 2>/dev/null | grep -oE "$MAC_RE" | sort -u
}

power_on_bt() {
	if ! bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
		echo "[*] Bluetooth is off, powering on..."
		bluetoothctl power on >/dev/null 2>&1 || true
		sleep 1
	fi
}

# Keep nudging the controller until BlueZ reports it connected. Returns 0 on
# success. Single connect calls can fail right after the pad wakes or after
# pairing, so poll the state rather than trusting the connect command.
wait_connected() {
	local mac="$1"
	local i
	for i in $(seq 1 300); do
		if bluetoothctl info "$mac" 2>/dev/null | grep -q "Connected: yes"; then
			echo "[*] connected: $mac"
			return 0
		fi
		timeout 5 bluetoothctl connect "$mac" >/dev/null 2>&1 || true
		sleep 0.5
	done
	echo "[!] timed out waiting for connection to $mac"
	return 1
}

power_on_bt

# 1. Already-paired controller: just wait for the PS button press.
known_macs=$(all_macs)
paired=""
for mac in $known_macs; do
	if is_dualsense "$mac"; then
		paired="$mac"
		break
	fi
done

if [[ -n "$paired" ]]; then
	echo "[*] found paired DualSense: $paired"
	echo "[*] press the PS button on the controller to connect (Ctrl-C to stop)..."
	wait_connected "$paired" && exit 0
	# fell through below as a fallback; not a hard error
fi

# 2. No (working) pairing yet: scan and pair on sight.
echo "[*] no working pairing found, scanning for new controllers..."
bluetoothctl scan on >/dev/null 2>&1 &
scan_pid=$!
trap 'kill "$scan_pid" 2>/dev/null || true; bluetoothctl scan off >/dev/null 2>&1 || true' EXIT

echo "[*] put the controller into pairing mode (PS + Share) if it is not already paired..."
for _ in $(seq 1 480); do
	for mac in $(all_macs); do
		if is_dualsense "$mac" && [[ "$mac" != "$paired" ]]; then
			echo "[*] found controller: $mac, pairing..."
			bluetoothctl pair "$mac" >/dev/null 2>&1 || true
			bluetoothctl trust "$mac" >/dev/null 2>&1 || true
			wait_connected "$mac" && exit 0
		fi
	done
	sleep 0.5
done

echo "[!] no DualSense found (gave up after ~4 minutes)"
exit 1