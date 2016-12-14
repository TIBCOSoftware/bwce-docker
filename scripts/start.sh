#!/bin/bash
#Set ENV Variables
export BWCE_HOME=/tmp
export APPDIR=${BWCE_HOME}
export MALLOC_ARENA_MAX=2
export MALLOC_MMAP_THRESHOLD_=1024
export MALLOC_TRIM_THRESHOLD_=1024
export MALLOC_MMAP_MAX_=65536
export BW_KEYSTORE_PATH=/resources/addons/certs
. ./scripts/setup.sh
STATUS=$?
if [ $STATUS == "1" ]; then
    echo "ERROR: Failed to setup BWCE runtime. See logs for more details."
    exit 1
fi
exec bash $BWCE_HOME/tibco.home/bw*/*/bin/startBWAppNode.sh
