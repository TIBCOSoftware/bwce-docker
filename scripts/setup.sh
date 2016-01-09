#!/bin/bash
export BW_KEYSTORE_DIR=/resources/addons/certs
if [ ! -d $HOME/tibco.home ];
then
	unzip -qq /resources/bwce-runtime/bwce.zip -d $HOME
	rm -rf /resources/bwce-runtime/bwce.zip
	chmod 755 $HOME/tibco.home/bwcf/1.*/bin/startBWAppNode.sh
	chmod 755 $HOME/tibco.home/bwcf/1.*/bin/bwappnode
	chmod 755 $HOME/tibco.home/tibcojre64/1.*/bin/java
	chmod 755 $HOME/tibco.home/tibcojre64/1.*/bin/javac
	touch $HOME/keys.properties
	mkdir $HOME/tmp
	ln -s /*.ear `echo $HOME/tibco.home/bwcf/1.*/bin`/bwapp.ear
	sed -i.bak "s#_APPDIR_#$HOME#g" $HOME/tibco.home/bw*/*/config/appnode_config.ini
	cd /java-code
	$HOME/tibco.home/tibcojre64/1.*/bin/javac -cp `echo $HOME/tibco.home/bwcf/*/system/shared/com.tibco.tpcl.com.fasterxml.jackson_*`/*:.:/tibco.home/tibcojre64/1.*/lib ProfileTokenResolver.java
fi

if [ -f /*.substvar ]; then
	cp -f /*.substvar $HOME/tmp/pcf.substvar # User provided profile
else	
	if [ ! -f /tmp/META-INF/default.substvar ]; then
    	unzip -qq `echo $HOME/tibco.home/bwcf/1.*/bin/bwapp.ear` -d /tmp
    fi	
	cp -f /tmp/META-INF/default.substvar $HOME/tmp/pcf.substvar # Hardcoded to default profile
fi	

cd /java-code
$HOME/tibco.home/tibcojre64/1.*/bin/java -cp `echo $HOME/tibco.home/bwcf/*/system/shared/com.tibco.tpcl.com.fasterxml.jackson_*`/*:.:/tibco.home/tibcojre64/1.*/lib ProfileTokenResolver
STATUS=$?
if [ $STATUS == "1" ]; then
    echo "ERROR: Failed to substitute properties in the application profile."
    exit 1 # terminate and indicate error
fi