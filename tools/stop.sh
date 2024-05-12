#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Sends a rapid fire of CAN messages that stop the motors.

killall digging_autonomy dumping_autonomy

while true; do
    # Stop the motors.
    cansend can0 001#00800080

    # Stop the actuators.
    cansend can0 003#80800000

    sleep 0.01
done
