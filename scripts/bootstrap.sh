#!/bin/bash
#Set ENV Variables
export BW_KEYSTORE_DIR=/resources/addons/certs

if [ ! -f /bwapp/pcf.substvar ];
then
	ln -s /*.ear /bwapp/bwapp.ear
    unzip -qq /bwapp/bwapp.ear -d /tmp
	ls -s /tmp/META-INF/default.substvar /bwapp/pcf.substvar # Hardcoded to default profile
	cd /java-code
	/tibco.home/tibcojre64/1.*/bin/javac -cp .:/tibco.home/tibcojre64/1.*/lib:/tibco.home/tibcojre64/1.*/bin ProfileTokenResolver.java
fi

cd /java-code
#Resolve Tokens in the profile
/tibco.home/tibcojre64/1.*/bin/java -cp .:/tibco.home/tibcojre64/1.*/lib:/tibco.home/tibcojre64/1.*/bin ProfileTokenResolver
STATUS=$?
if [ $STATUS == "1" ]; then
    echo "ERROR: Failed to substitute properties in the application profile."
    exit 1 # terminate and indicate error
fi
exec /tibco.home/bwcf/1.*/bin/startBWAppNode.sh