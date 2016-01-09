#!/bin/bash
#Set ENV Variables
export APPDIR=$HOME
sh /scripts/setup.sh
exec sh $HOME/tibco.home/bw*/*/bin/startBWAppNode.sh