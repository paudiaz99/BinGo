#!/bin/bash

export GDS3D_PATH="your/path/to/GDS3D"
export RUN_NAME="RUN_2026-02-21_21-32-16"
export PROJECT_PATH="your/path/to/BinGo"

if [ "$1" == "gds3d" ]; then
    ${GDS3D_PATH}/mac/GDS3D.app/Contents/MacOS/GDS3D -p ${GDS3D_PATH}/techfiles/sky130.txt -i ${PROJECT_PATH}/synth/runs/${RUN_NAME}/final/gds/top.gds
elif [ "$1" == "openroad" ]; then
    librelane --last-run --flow openinopenroad ${PROJECT_PATH}/synth/config.json
elif [ "$1" == "klayout" ]; then
    librelane --last-run --flow openinklayout ${PROJECT_PATH}/synth/config.json
else
    echo "Usage: ./visualization.sh [gds3d|openroad|klayout]"
fi