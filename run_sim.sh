#!/bin/bash

xhost +local:root

CURR_DISPLAY=$DISPLAY

docker exec -it ib2_simulator bash -c "\
	export DISPLAY=$CURR_DISPLAY && \
	source /opt/ros/melodic/setup.bash
	source /home/nvidia/IB2/Int-Ball2_platform_simulator/devel/setup.bash
	rosrun platform_sim_tools simulator_bringup.sh
"

xhost -local:root
