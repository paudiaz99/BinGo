#!/bin/bash

export PROJECT_PATH="$1"

if ["$1" == ""] ; then
    echo "Please provide the path to the project."
    exit 1
fi

# Run the synthesis flow
librelane ${PROJECT_PATH}/synth/config.json