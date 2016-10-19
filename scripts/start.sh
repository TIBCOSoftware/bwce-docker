#!/bin/bash
#Set ENV Variables
export APPDIR=$HOME
export MALLOC_ARENA_MAX=2
export MALLOC_MMAP_THRESHOLD_=1024
export MALLOC_TRIM_THRESHOLD_=1024
export MALLOC_MMAP_MAX_=65536
export BW_KEYSTORE_PATH=/resources/addons/certs
bash /scripts/setup.sh
STATUS=$?
if [ $STATUS == "1" ]; then
    echo "ERROR: Failed to setup BWCE runtime. See logs for more details."
    exit 1
fi
export JAVA_HOME=$HOME/tibco.home/tibcojre64/1.8.0
exec bash $HOME/tibco.home/bw*/*/bin/startBWAppNode.sh
