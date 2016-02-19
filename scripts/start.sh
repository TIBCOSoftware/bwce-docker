#!/bin/bash
#Set ENV Variables
export APPDIR=$HOME
bash /scripts/setup.sh
exec bash $HOME/tibco.home/bw*/*/bin/startBWAppNode.sh