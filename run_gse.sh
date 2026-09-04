#!/bin/bash

xhost +local:root

CURR_DISPLAY=$DISPLAY

docker exec -it ib2_simulator bash -c "\
	export DISPLAY=$CURR_DISPLAY && \
	source /opt/ros/melodic/setup.bash
	source /home/nvidia/IB2/Int-Ball2_platform_gse/devel/setup.bash
	roslaunch platform_gui bringup.launch
"

xhost -local:root
