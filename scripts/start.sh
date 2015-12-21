#!/bin/bash
#Set ENV Variables
export BW_KEYSTORE_DIR=/resources/addons/certs
export JACKSON_LIB_PATH=`echo /tibco.home/bwcf/*/system/shared/com.tibco.tpcl.com.fasterxml.jackson_*`

if [ ! -f /bwapp/pcf.substvar ];
then
	sh /scripts/setup.sh
fi
cd /java-code
#Resolve Tokens in the profile
/tibco.home/tibcojre64/1.*/bin/java -cp `echo /tibco.home/bwcf/*/system/shared/com.tibco.tpcl.com.fasterxml.jackson_*`/*:.:/tibco.home/tibcojre64/1.*/lib ProfileTokenResolver
STATUS=$?
if [ $STATUS == "1" ]; then
    echo "ERROR: Failed to substitute properties in the application profile."
    exit 1 # terminate and indicate error
fi
exec sh /tibco.home/bwcf/1.*/bin/startBWAppNode.sh