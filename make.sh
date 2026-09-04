#!/bin/bash

cd "$(dirname "$0")"

docker run --rm \
	-v "$(pwd)/ib2_user_ws:$(pwd)/ib2_user_ws" \
	ib2_simulator:latest \
	bash -c "\
		   echo 'Sourcing ROS and workspace setup files...' && \
		   source /opt/ros/melodic/setup.bash && \
           source /home/nvidia/IB2/Int-Ball2_platform_simulator/devel/setup.bash && \
		   echo 'Building the workspace...' && \
           cd $(pwd)/ib2_user_ws && catkin_make"

if [ $(docker ps -a -q --filter "name=^/ib2_simulator$") ]; then
	echo "Restarting the existing container..."
	docker compose restart
fi
