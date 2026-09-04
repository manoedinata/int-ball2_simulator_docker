#!/bin/bash

docker exec -it ib2_simulator bash -c "\
	source /opt/ros/melodic/setup.bash && \
	source /home/nvidia/IB2/Int-Ball2_platform_simulator/devel/setup.bash && \
	bash
"
