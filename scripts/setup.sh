#!/bin/bash
checkProfile()
{
BUILD_DIR=/tmp
defaultProfile=default.substvar
manifest=$BUILD_DIR/META-INF/MANIFEST.MF
bwAppConfig="TIBCO-BW-ConfigProfile"
bwAppNameHeader="Bundle-SymbolicName"
bwEdition='bwcf'
if [ -f ${manifest} ]; then
	bwAppProfileStr=`grep -o $bwAppConfig.*.substvar ${manifest}`
	bwEditionHeaderStr=`grep -E $bwEdition ${manifest}`
	res=$?
	if [ ${res} -eq 0 ]; then
		echo " "
	else
		echo "${bwEdition} header not detected in ${manifest}"
		exit 1
	fi
fi
arr=$(echo $bwAppProfileStr | tr "/" "\n")

for x in $arr
do
    case "$x" in 
	*substvar)
	defaultProfile=$x;;esac	
done

if [ -z ${BW_PROFILE:=${defaultProfile}} ]; then echo "BW_PROFILE is unset. Set it to $defaultProfile"; 
else 
		case $BW_PROFILE in
 		*.substvar ) ;;
		* ) BW_PROFILE="${BW_PROFILE}.substvar";;esac
		echo "BW_PROFILE is set to '$BW_PROFILE'";
fi
}


setRouteInterface()
{
	appnodeConfigFile=$HOME/tibco.home/bw*/*/config/appnode_config.ini
	printf '%s\n' "bwce.edition=bwce" >> $appnodeConfigFile
	if [[ ${BW_SWAGGER_SERVICE} ]]; then
		s_host=${BW_SWAGGER_SERVICE}_SERVICE_HOST
		s_port=${BW_SWAGGER_SERVICE}_SERVICE_PORT
		printf '%s\n' "bw.rest.docApi.reverseProxy.hostName=${!s_host}" >> $appnodeConfigFile
		printf '%s\n' "bw.rest.docApi.reverseProxy.port=${!s_port}" >> $appnodeConfigFile
	fi

}

export BW_KEYSTORE_DIR=/resources/addons/certs
if [ ! -d $HOME/tibco.home ];
then
	unzip -qq /resources/bwce-runtime/bwce.zip -d $HOME
	rm -rf /resources/bwce-runtime/bwce.zip
	chmod 755 $HOME/tibco.home/bw*/*/bin/startBWAppNode.sh
	chmod 755 $HOME/tibco.home/bw*/*/bin/bwappnode
	chmod 755 $HOME/tibco.home/tibcojre64/*/bin/java
	chmod 755 $HOME/tibco.home/tibcojre64/*/bin/javac
	touch $HOME/keys.properties
	mkdir $HOME/tmp
	jarFolder=/resources/addons/jars
	if [ "$(ls $jarFolder)"  ]; then
		#Copy jars to Hotfix
	  	cp -r /resources/addons/jars/* `echo $HOME/tibco.home/bw*/*`/system/hotfix/shared
	fi
	ln -s /*.ear `echo $HOME/tibco.home/bw*/*/bin`/bwapp.ear
	sed -i.bak "s#_APPDIR_#$HOME#g" $HOME/tibco.home/bw*/*/config/appnode_config.ini
	unzip -qq `echo $HOME/tibco.home/bw*/1.*/bin/bwapp.ear` -d /tmp
	cd /java-code
	$HOME/tibco.home/tibcojre64/1.*/bin/javac -cp `echo $HOME/tibco.home/bw*/*/system/shared/com.tibco.tpcl.com.fasterxml.jackson_*`/*:.:$HOME/tibco.home/tibcojre64/1.*/lib ProfileTokenResolver.java
fi

setRouteInterface
checkProfile
if [ -f /*.substvar ]; then
	cp -f /*.substvar $HOME/tmp/pcf.substvar # User provided profile
else
	cp -f /tmp/META-INF/$BW_PROFILE $HOME/tmp/pcf.substvar
fi

cd /java-code
$HOME/tibco.home/tibcojre64/1.*/bin/java -cp `echo $HOME/tibco.home/bw*/*/system/shared/com.tibco.tpcl.com.fasterxml.jackson_*`/*:.:$HOME/tibco.home/tibcojre64/1.*/lib ProfileTokenResolver
STATUS=$?
if [ $STATUS == "1" ]; then
    echo "ERROR: Failed to substitute properties in the application profile."
    exit 1 # terminate and indicate error
fi