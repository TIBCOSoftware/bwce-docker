#!/bin/bash
#
# Copyright 2012 - 2016 by TIBCO Software Inc. 
# All rights reserved.
#
# This software is confidential and proprietary information of
# TIBCO Software Inc.
#
#

print_Debug()
{
		if [[ ${BW_LOGLEVEL} && "${BW_LOGLEVEL,,}"="debug" ]]; then
 			echo $1 
 		fi
}
extract ()
{
if [ -f $1 ] ; then
  case $1 in
    *.tar.gz)  tar xvfz $1;;
    *.gz)      gunzip $1;;
    *.tar)     tar xvf $1;;
    *.tgz)     tar xvzf $1;;
    *.tar.bz2) tar xvjf $1;;
    *.bz2)     bunzip2 $1;;
    *.rar)     unrar x $1;;
    *.tbz2)    tar xvjf $1;;
    *.zip)     unzip -q $1;;
    *.Z)       uncompress $1;;
    *)         echo "can't extract from $1";;
  esac
else
  echo "no file called $1"
fi
}


checkProfile()
{
	BUILD_DIR=/tmp
	defaultProfile=default.substvar
	manifest=$BUILD_DIR/META-INF/MANIFEST.MF
	bwAppConfig="TIBCO-BW-ConfigProfile"
	bwAppNameHeader="Bundle-SymbolicName"
	bwEdition='bwcf'
	bwceTarget='TIBCO-BWCE-Edition-Target:'
	if [ -f ${manifest} ]; then
		bwAppProfileStr=`grep -o $bwAppConfig.*.substvar ${manifest}`
		bwBundleAppName=`while read line; do printf "%q\n" "$line"; done<${manifest} | awk '/.*:/{printf "%s%s", (NR==1)?"":RS,$0;next}{printf "%s", FS $0}END{print ""}' | grep -o $bwAppNameHeader.* | cut -d ":" -f2 | tr -d '[[:space:]]' | sed "s/\\\\\r'//g" | sed "s/$'//g"`
		bwEditionHeaderStr=`grep -E $bwEdition ${manifest}`
		res=$?
		if [ ${res} -eq 0 ]; then
			echo " "
		else
			echo "Application [$bwBundleAppName] is not supported in TIBCO BusinessWorks Container Edition. Convert this application to TIBCO BusinessWorks Container Edition using TIBCO BusinessWorks Container Edition Studio. Refer Conversion Guide for more details."
			exit 1
		fi
		#bwceTargetHeaderStr=`grep -E $bwceTarget ${manifest}`
		#res=$?
		#if [ ${res} -eq 0 ]; then
			#bwceTargetStr=`echo "$bwceTargetHeaderStr" | grep -E 'docker'`
			#res2=$?
			#if [ ${res2} -eq 0 ]; then
				#echo ""
			#else
				#echo "Application [$bwBundleAppName] is not supported in the Docker platform and cannot be started. You should convert this application using TIBCO BusinessWorks Container Edition Studio. Refer Application Development guide for more details."
				#exit 1
			#fi
		#else
		 	#echo "Application [$bwBundleAppName] is not supported in the Docker platform and cannot be started. You should convert this application using TIBCO BusinessWorks Container Edition Studio. Refer Application Development guide for more details."
			#exit 1
		#fi

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

setLogLevel()
{
	logback=$HOME/tibco.home/bw*/*/config/logback.xml
	if [[ ${BW_LOGLEVEL} && "${BW_LOGLEVEL,,}"="debug" ]]; then
		if [ -e ${logback} ]; then
			sed -i.bak "/<root/ s/\".*\"/\"$BW_LOGLEVEL\"/Ig" $logback
			echo "The loglevel is set to $BW_LOGLEVEL level"
		fi
	else
			sed -i.bak "/<root/ s/\".*\"/\"ERROR\"/Ig" $logback
			#echo "The loglevel set to ERROR level"
	fi
}


checkEnvSubstituteConfig()
{
	bwappnodeTRA=$HOME/tibco.home/bw*/*/bin/bwappnode.tra
	appnodeConfigFile=$HOME/tibco.home/bw*/*/config/appnode_config.ini
if [[ ${BW_JAVA_OPTS} ]]; then
		if [ -e ${bwappnodeTRA} ]; then
			 sed -i.bak "/java.extended.properties/s/$/ $BW_JAVA_OPTS/" $bwappnodeTRA
			 echo "appended $BW_JAVA_OPTS to java.extend.properties"
		fi
fi

if [[ ${BW_ENGINE_THREADCOUNT} ]]; then
		if [ -e ${appnodeConfigFile} ]; then
			printf '%s\n' "bw.engine.threadCount=$BW_ENGINE_THREADCOUNT" >> $appnodeConfigFile
			echo "set BW_ENGINE_THREADCOUNT to $BW_ENGINE_THREADCOUNT"
		fi
fi
if [[ ${BW_ENGINE_STEPCOUNT} ]]; then
		if [ -e ${appnodeConfigFile} ]; then
			printf '%s\n' "bw.engine.stepCount=$BW_ENGINE_STEPCOUNT" >> $appnodeConfigFile
			echo "set BW_ENGINE_STEPCOUNT to $BW_ENGINE_STEPCOUNT"
		fi
fi
if [[ ${BW_APPLICATION_JOB_FLOWLIMIT} ]]; then
		if [ -e ${appnodeConfigFile} ]; then

			printf '%s\n' "bw.application.job.flowlimit.$bwBundleAppName=$BW_APPLICATION_JOB_FLOWLIMIT" >> $appnodeConfigFile
			echo "set BW_APPLICATION_JOB_FLOWLIMIT to $BW_APPLICATION_JOB_FLOWLIMIT"
		fi
fi

if [[  $BW_LOGLEVEL = "DEBUG" ]]; then
	if [[ ${BW_APPLICATION_JOB_FLOWLIMIT} ]] || [[ ${BW_ENGINE_STEPCOUNT} ]] || [[ ${BW_ENGINE_THREADCOUNT} ]]; then
		echo "---------------------------------------"
		cat $appnodeConfigFile
		echo "---------------------------------------"
	fi
fi
}

checkJarsPalettes()
{
BW_VERSION=`ls $HOME/tibco.home/bw*/`

pluginFolder=/resources/addons/plugins
if [ "$(ls $pluginFolder)"  ]; then 
	print_Debug "Adding addional plugins"
	echo -e "name=Addons Factory\ntype=bw6\nlayout=bw6ext\nlocation=$HOME/tibco.home/addons" > `echo $HOME/tibco.home/bw*/*/ext/shared`/addons.link
	# unzip whatever is there not done
for name in $(find $pluginFolder -type f); 
do	
	# filter out hidden files
	if [[  "$(basename $name )" != .* ]];then
   		extract $name
		mkdir -p $HOME/tibco.home/addons/runtime/plugins/ && mv runtime/plugins/* "$_"
		#mkdir -p $HOME/tibco.home/addons/lib/ && mv lib/* "$_"/${name##*/}.ini
	fi
done
fi
}

checkAgents()
{
	agentFolder=/resources/addons/monitor-agents

	if [ "$(ls $agentFolder)"  ]; then 
		print_Debug "Adding monitoring jars"

		for name in $(find $agentFolder -type f); 
do	
	# filter out hidden files
	if [[  "$(basename $name )" != .* ]];then
		mkdir -p $HOME/agent/
   		unzip -q $name -d $HOME/agent/
	fi
done
		
	fi

}


export BW_KEYSTORE_PATH=/resources/addons/certs
if [ ! -d $HOME/tibco.home ];
then
	unzip -qq /resources/bwce-runtime/bwce*.zip -d $HOME
	rm -rf /resources/bwce-runtime/bwce*.zip
	chmod 755 $HOME/tibco.home/bw*/*/bin/startBWAppNode.sh
	chmod 755 $HOME/tibco.home/bw*/*/bin/bwappnode
	chmod 755 $HOME/tibco.home/tibcojre64/*/bin/java
	chmod 755 $HOME/tibco.home/tibcojre64/*/bin/javac
	touch $HOME/keys.properties
	mkdir $HOME/tmp
	addonFolder=/resources/addons
	if [ -d ${addonFolder} ]; then
		checkJarsPalettes
		checkAgents
		checkLibs
		jarFolder=/resources/addons/jars
		if [ "$(ls $jarFolder)"  ]; then
		#Copy jars to Hotfix
	  		cp -r /resources/addons/jars/* `echo $HOME/tibco.home/bw*/*`/system/hotfix/shared
		fi
	fi
	ln -s /*.ear `echo $HOME/tibco.home/bw*/*/bin`/bwapp.ear
	sed -i.bak "s#_APPDIR_#$HOME#g" $HOME/tibco.home/bw*/*/config/appnode_config.ini
	unzip -qq `echo $HOME/tibco.home/bw*/*/bin/bwapp.ear` -d /tmp
	setLogLevel
	checkEnvSubstituteConfig
	cd /java-code
	$HOME/tibco.home/tibcojre64/1.*/bin/javac -cp `echo $HOME/tibco.home/bw*/*/system/shared/com.tibco.tpcl.com.fasterxml.jackson_*`/*:`echo $HOME/tibco.home/bw*/*/system/shared/com.tibco.bw.tpcl.org.codehaus.jettison_*`/*:.:$HOME/tibco.home/tibcojre64/1.*/lib ProfileTokenResolver.java
fi

checkProfile
if [ -f /*.substvar ]; then
	cp -f /*.substvar $HOME/tmp/pcf.substvar # User provided profile
else
	cp -f /tmp/META-INF/$BW_PROFILE $HOME/tmp/pcf.substvar
fi

cd /java-code
$HOME/tibco.home/tibcojre64/1.*/bin/java -cp `echo $HOME/tibco.home/bw*/*/system/shared/com.tibco.tpcl.com.fasterxml.jackson_*`/*:`echo $HOME/tibco.home/bw*/*/system/shared/com.tibco.bw.tpcl.org.codehaus.jettison_*`/*:.:$HOME/tibco.home/tibcojre64/1.*/lib -DBWCE_APP_NAME=$bwBundleAppName ProfileTokenResolver
STATUS=$?
if [ $STATUS == "1" ]; then
    exit 1 # terminate and indicate error
fi
