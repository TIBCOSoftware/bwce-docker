#!/bin/bash
export JACKSON_LIB_PATH=`echo /tibco.home/bwcf/*/system/shared/com.tibco.tpcl.com.fasterxml.jackson_*`
unzip -qq /resources/bwce-runtime/bwce.zip -d /
rm -rf /resources/bwce-runtime/bwce.zip
chmod 755 /tibco.home/bwcf/1.*/bin/startBWAppNode.sh
chmod 755 /tibco.home/bwcf/1.*/bin/bwappnode
chmod 755 /tibco.home/tibcojre64/1.*/bin/java
chmod 755 /tibco.home/tibcojre64/1.*/bin/javac
mkdir /bwapp
ln -s /*.ear /bwapp/bwapp.ear
if [ -f /*.substvar ]; then
	ln -s /*.substvar /bwapp/pcf.substvar # User provided profile
else	
    unzip -qq /bwapp/bwapp.ear -d /tmp
	ln -s /tmp/META-INF/default.substvar /bwapp/pcf.substvar # Hardcoded to default profile
fi	
cd /java-code
/tibco.home/tibcojre64/1.*/bin/javac -cp `echo /tibco.home/bwcf/*/system/shared/com.tibco.tpcl.com.fasterxml.jackson_*`/*:.:/tibco.home/tibcojre64/1.*/lib ProfileTokenResolver.java