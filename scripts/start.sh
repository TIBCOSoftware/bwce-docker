#!/bin/bash
#Set ENV Variables
export APPDIR=$HOME
sh /scripts/setup.sh
exec sh $HOME/tibco.home/bwcf/1.*/bin/startBWAppNode.sh