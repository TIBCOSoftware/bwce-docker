#!/bin/bash
export BW_KEYSTORE_DIR=/resources/addons/certs
if [ ! -d /tibco.home ];
then
	unzip -qq /resources/bwce-runtime/bwce.zip -d /
	rm -rf /resources/bwce-runtime/bwce.zip
	chmod 755 /tibco.home/bwcf/1.*/bin/startBWAppNode.sh
	chmod 755 /tibco.home/bwcf/1.*/bin/bwappnode
	chmod 755 /tibco.home/tibcojre64/1.*/bin/java
	chmod 755 /tibco.home/tibcojre64/1.*/bin/javac
	mkdir /bwapp
	touch $HOME/keys.properties
	ln -s /*.ear /bwapp/bwapp.ear
	cd /java-code
	/tibco.home/tibcojre64/1.*/bin/javac -cp `echo /tibco.home/bwcf/*/system/shared/com.tibco.tpcl.com.fasterxml.jackson_*`/*:.:/tibco.home/tibcojre64/1.*/lib ProfileTokenResolver.java
fi

if [ -f /*.substvar ]; then
	cp -f /*.substvar /bwapp/pcf.substvar # User provided profile
else	
	if [ ! -f /tmp/META-INF/default.substvar ]; then
    	unzip -qq /bwapp/bwapp.ear -d /tmp
    fi	
	cp -f /tmp/META-INF/default.substvar /bwapp/pcf.substvar # Hardcoded to default profile
fi	

cd /java-code
/tibco.home/tibcojre64/1.*/bin/java -cp `echo /tibco.home/bwcf/*/system/shared/com.tibco.tpcl.com.fasterxml.jackson_*`/*:.:/tibco.home/tibcojre64/1.*/lib ProfileTokenResolver
STATUS=$?
if [ $STATUS == "1" ]; then
    echo "ERROR: Failed to substitute properties in the application profile."
    exit 1 # terminate and indicate error
fi