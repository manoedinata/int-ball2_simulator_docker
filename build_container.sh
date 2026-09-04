#!/bin/bash

docker build --build-arg HOST_USER_PATH="$(pwd)" --build-arg QT_EMAIL=manoedinata@gmail.com --build-arg QT_PASSWORD="yahhahayyuk####" -t ib2_simulator:latest .
