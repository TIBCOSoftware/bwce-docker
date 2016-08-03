#!/bin/bash
#Set ENV Variables
export APPDIR=$HOME
bash /scripts/setup.sh
STATUS=$?
if [ $STATUS == "1" ]; then
    echo "ERROR: Failed to setup BWCE runtime. See logs for more details."
    exit 1
fi
exec bash $HOME/tibco.home/bw*/*/bin/startBWAppNode.sh
