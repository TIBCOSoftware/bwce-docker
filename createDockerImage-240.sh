#!/bin/bash
# Copyright (c) 2016, TIBCO Software Inc. All rights reserved.
# You may not use this file except in compliance with the license 
# terms contained in the TIBCO License.md file provided with this file.


if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "Usage: ./createDockerImage.sh <path/to/bwce-runtime-2.3.1.zip> <Tag>"
    printf "\t %s \t\t %s \n\t\t\t\t %s \n" "Location of runtime zip (bwce-runtime-<version>.zip)"
    printf "\t %s \t\t %s \n\t\t\t\t %s \n" "Tag. Eg: bwce:v2.0.0"
    exit 1
fi
zipLocation=$1

if [ -z "$2"  ]; then
	tag="bwce-240:latest"
	echo "Tag is set to bwce-240:latest"
else
	tag=$2
fi

mkdir -p resources/bwce-runtime && cp -f $zipLocation "$_"

docker build -f Dockerfile -t $tag .
