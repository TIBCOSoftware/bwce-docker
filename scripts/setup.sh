#!/bin/bash
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
			echo "Application [$bwBundleAppName] is not supported in TIBCO BusinessWorks Container Edition. Convert this application to TIBCO BusinessWorks Container Edition using TIBCO BusinessWorks Container Edition Studio."
			exit 1
		fi
		bwceTargetHeaderStr=`grep -E $bwceTarget ${manifest}`
		res=$?
		if [ ${res} -eq 0 ]; then
			bwceTargetStr=`echo "$bwceTargetHeaderStr" | grep -E 'docker'`
			res2=$?
			if [ ${res2} -eq 0 ]; then
				echo ""
			else
				echo "Application [$bwBundleAppName] is not supported in the Docker platform and cannot be started. You need to convert this application using TIBCO BusinessWorks Container Edition Studio. Refer Application Development guide for more details."
				exit 1
			fi
		else
		 	echo "Application [$bwBundleAppName] is not supported in the Docker platform and cannot be started. You need to convert this application using TIBCO BusinessWorks Container Edition Studio. Refer Application Development guide for more details."
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







export BW_KEYSTORE_DIR=/resources/addons/certs
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
	jarFolder=/resources/addons/jars
	if [ "$(ls $jarFolder)"  ]; then
		#Copy jars to Hotfix
	  	cp -r /resources/addons/jars/* `echo $HOME/tibco.home/bw*/*`/system/hotfix/shared
	fi
	ln -s /*.ear `echo $HOME/tibco.home/bw*/*/bin`/bwapp.ear
	sed -i.bak "s#_APPDIR_#$HOME#g" $HOME/tibco.home/bw*/*/config/appnode_config.ini
	unzip -qq `echo $HOME/tibco.home/bw*/*/bin/bwapp.ear` -d /tmp
	setLogLevel
	checkEnvSubstituteConfig
	cd /java-code
	$HOME/tibco.home/tibcojre64/1.*/bin/javac -cp `echo $HOME/tibco.home/bw*/*/system/shared/com.tibco.tpcl.com.fasterxml.jackson_*`/*:.:$HOME/tibco.home/tibcojre64/1.*/lib ProfileTokenResolver.java
fi

checkProfile
if [ -f /*.substvar ]; then
	cp -f /*.substvar $HOME/tmp/pcf.substvar # User provided profile
else
	cp -f /tmp/META-INF/$BW_PROFILE $HOME/tmp/pcf.substvar
fi

cd /java-code
$HOME/tibco.home/tibcojre64/1.*/bin/java -cp `echo $HOME/tibco.home/bw*/*/system/shared/com.tibco.tpcl.com.fasterxml.jackson_*`/*:.:$HOME/tibco.home/tibcojre64/1.*/lib -DBWCE_APP_NAME=$bwBundleAppName ProfileTokenResolver
STATUS=$?
if [ $STATUS == "1" ]; then
    exit 1 # terminate and indicate error
fi
