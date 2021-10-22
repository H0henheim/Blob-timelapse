#!/bin/bash

DIRECTORY="/var/www/html"
DIR_DATE=$(date +"%Y-%m-%d_%H:%M:%S")

function LED_on()
{
	# Set up GPIO 4 and set to output
	echo 4 > /sys/class/gpio/export
	echo out > /sys/class/gpio/gpio4/direction
	# Write output
	echo 1 > /sys/class/gpio/gpio4/value
}

function LED_off()
{
	echo 0 > /sys/class/gpio/gpio4/value
	echo 4 > /sys/class/gpio/unexport
}

function create_dir()
{
	mkdir $DIRECTORY/$DIR_DATE
}

function take_picture()
{
	local DATE=$1
	local pic=$2
	local nb_picture=$3
	pic=$((pic+1))
	echo -e "Taking picture $pic/$nb_picture : timelapse_$DATE.jpg"
	echo "Taking picture $pic/$nb_picture : timelapse_$DATE.jpg" >> $DIRECTORY/$DIR_DATE/timelapse.log

	LED_on
	raspistill -o $DIRECTORY/$DIR_DATE/timelapse\_$DATE.jpg
	sleep 2
	LED_off
}

function timelapse()
{
	local i=0
	local sample_period=600 # time interval between 2 pictures (in second)
	local nb_picture=144 # set max number of picture to take
	# experience duration = sample_period x nb_pictures. Ex : 10s x 12 = 2min
	while [ $i -lt $nb_picture ]
	do
		DATE=$(date +"%Y-%m-%d_%H:%M:%S")
		take_picture $DATE $i $nb_picture
		sleep $sample_period
		i=$((i+1))
	done
}

# Using mencoder
function encoding_1()
{
	local DATE=$(date +"%Y-%m-%d_%H:%M:%S")
	mencoder -nosound -ovc lavc -lavcopts vcodec=mpeg4 \
		-o $DIRECTORY/$DIR_DATE/timelapse\_$DATE.avi \
		-mf type=jpeg:fps=15 mf://$DIRECTORY/$DIR_DATE/*.jpg &>/dev/null
}

# Using ffmpeg
function encoding_2()
{
	local DATE=$(date +"%Y-%m-%d_%H:%M:%S")
	ffmpeg -framerate 15 -pattern_type glob -i "$DIRECTORY/$DIR_DATE/*.jpg" \
		-s:v hd1080 -c:v libx264 -crf 1 \
		$DIRECTORY/$DIR_DATE/timelapse\_$DATE.mkv &>/dev/null
}


echo -e "Starting timelapse"
create_dir
timelapse
echo -e "Creating video..."
#encoding_1
encoding_2
echo -e "Done"
chown -R blob:www-data $DIRECTORY/$DIR_DATE
echo -e "Timelapse terminated"
