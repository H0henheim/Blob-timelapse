#!/bin/bash

# Set up GPIO 4 and set to output
echo 4 > /sys/class/gpio/export
echo out > /sys/class/gpio/gpio4/direction
# Write output
echo 1 > /sys/class/gpio/gpio4/value

sleep 1
raspistill -o /var/www/html/test.jpg
sleep 2

### Turn off LED ###

echo 0 > /sys/class/gpio/gpio4/value
echo 4 > /sys/class/gpio/unexport

