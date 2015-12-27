#!/bin/bash
#Set ENV Variables
if [ ! -f /bwapp/pcf.substvar ];
then
	sh /scripts/setup.sh
fi
exec sh /tibco.home/bwcf/1.*/bin/startBWAppNode.sh