#!/bin/bash

# https://elinux.org/RPi_GPIO_Code_Samples#Shell

# Has to be run as root

### Turn on LED on GPIO4 ###

# Set up GPIO 4 and set to output
echo 4 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio4/direction
# Write output
echo 1 > /sys/class/gpio/gpio4/value

sleep 5

### Turn off LED ###

echo 0 > /sys/class/gpio/gpio4/value
echo 4 > /sys/class/gpio/unexport
