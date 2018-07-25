:: Copyright 2012 - 2016 by TIBCO Software Inc. 
:: All rights reserved.
:: This software is confidential and proprietary information of TIBCO Software Inc.
::ECHO OFF
CALL:print_Debug 100

:print_Debug
	IF DEFINED BW_LOGLEVEL (
		IF "%BW_LOGLEVEL%"=="debug" (
			ECHO %~1
		)
 	)
GOTO:EOF

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
	BUILD_DIR=c:/tmp
	defaultProfile=default.substvar
	manifest=$BUILD_DIR/META-INF/MANIFEST.MF
	bwAppConfig="TIBCO-BW-ConfigProfile"
	bwAppNameHeader="Bundle-SymbolicName"
	bwEdition='bwcf'
	#bwceTarget='TIBCO-BWCE-Edition-Target:'
	if [ -f ${manifest} ]; then
		bwAppProfileStr=`grep -o $bwAppConfig.*.substvar ${manifest}`
		bwBundleAppName=`while read line; do printf "%q\n" "$line"; done<${manifest} | awk '/.*:/{printf "%s%s", (NR==1)?"":RS,$0;next}{printf "%s", FS $0}END{print ""}' | grep -o $bwAppNameHeader.* | cut -d ":" -f2 | tr -d '[[:space:]]' | sed "s/\\\\\r'//g" | sed "s/$'//g"`
		if [ "$DISABLE_BWCE_EAR_VALIDATION" != true ]; then
			bwEditionHeaderStr=`grep -E $bwEdition ${manifest}`
			res=$?
			if [ ${res} -eq 0 ]; then
				print_Debug " "
			else
				echo "ERROR: Application [$bwBundleAppName] is not supported in TIBCO BusinessWorks Container Edition. Convert this application to TIBCO BusinessWorks Container Edition using TIBCO Business Studio Container Edition. Refer Conversion Guide for more details."
				exit 1
			fi
		else
			print_Debug "BWCE EAR Validation disabled."
		fi

		for name in $(find $BUILD_DIR -path $BUILD_DIR/tibco.home -prune -o -type f -iname "*.jar");
		do
			if [[ $name == *.jar ]]; then
			        mkdir -p $BUILD_DIR/temp 
				unzip -o -q $name -d $BUILD_DIR/temp
				MANIFESTMF=$BUILD_DIR/temp/META-INF/MANIFEST.MF

				bwcePaletteStr=`tr -d '\n\r ' < ${MANIFESTMF} | grep -E 'bw.rv'`
				palette_res=$?

				bwcePolicyStr=`tr -d '\n\r ' < ${MANIFESTMF} | grep -E 'bw.authxml|bw.cred|bw.ldap|bw.wss|bw.dbauth|bw.kerberos|bw.realmdb|bw.ldaprealm|bw.userid'`
				policy_res=$?
				rm -rf $BUILD_DIR/temp

				if [ ${palette_res} -eq 0 ]; then
	 				echo "ERROR: Application [$bwBundleAppName] is using unsupported RV palette and can not be deployed in Docker. Rebuild your application for Docker using TIBCO Business Studio Container Edition."
	 				exit 1
				fi

				if [ ${policy_res} -eq 0 ]; then
					POLICY_ENABLED="true"
					break
				fi
			fi
		done
	fi

	arr=$(echo $bwAppProfileStr | tr "/" "\n")
	for x in $arr
	do
    	case "$x" in 
		*substvar)
		defaultProfile=$x;;esac	
	done

	if [ -z ${BW_PROFILE:=${defaultProfile}} ]; then
		echo "BW_PROFILE is unset. Set it to $defaultProfile"; 
	else 
		case $BW_PROFILE in
 		*.substvar ) ;;
		* ) BW_PROFILE="${BW_PROFILE}.substvar";;esac
		echo "BW_PROFILE is set to '$BW_PROFILE'";
	fi
}

checkPolicy()
{
	if [[ $POLICY_ENABLED = "true" ]]; then
		if [ -e ${appnodeConfigFile} ]; then
			printf '%s\n' "bw.governance.enabled=true" >> $appnodeConfigFile
			print_Debug "Set bw.governance.enabled=true"
		fi
	fi
}

setLogLevel()
{
	logback=$BWCE_HOME/tibco.home/bw*/*/config/logback.xml
	if [[ ${BW_LOGLEVEL} && "${BW_LOGLEVEL,,}"="debug" ]]; then
		if [ -e ${logback} ]; then
			sed -i.bak "/<root/ s/\".*\"/\"$BW_LOGLEVEL\"/Ig" $logback
			echo "The loglevel is set to $BW_LOGLEVEL level"
		fi
	else
			sed -i.bak "/<root/ s/\".*\"/\"ERROR\"/Ig" $logback
	fi
}


checkEnvSubstituteConfig()
{
	bwappnodeTRA=$BWCE_HOME/tibco.home/bw*/*/bin/bwappnode.tra
	bwappnodeFile=$BWCE_HOME/tibco.home/bw*/*/bin/bwappnode
	#appnodeConfigFile=$BWCE_HOME/tibco.home/bw*/*/config/appnode_config.ini
	manifest=/tmp/META-INF/MANIFEST.MF
	bwAppNameHeader="Bundle-SymbolicName"
	bwBundleAppName=`while read line; do printf "%q\n" "$line"; done<${manifest} | awk '/.*:/{printf "%s%s", (NR==1)?"":RS,$0;next}{printf "%s", FS $0}END{print ""}' | grep -o $bwAppNameHeader.* | cut -d ":" -f2 | tr -d '[[:space:]]' | sed "s/\\\\\r'//g" | sed "s/$'//g"`
	export BWCE_APP_NAME=$bwBundleAppName 	
	if [ -e ${bwappnodeTRA} ]; then
		sed -i 's?-Djava.class.path=?-Djava.class.path=$ADDONS_HOME/lib:?' $bwappnodeTRA
		print_Debug "Appended ADDONS_HOME/lib in bwappnode.tra file"
	fi
	if [ -e ${bwappnodeFile} ]; then
		sed -i 's?-Djava.class.path=?-Djava.class.path=$ADDONS_HOME/lib:?' $bwappnodeFile
		print_Debug "Appended ADDONS_HOME/lib in bwappnode file"
	fi
	if [[ ${BW_JAVA_OPTS} ]]; then
		if [ -e ${bwappnodeTRA} ]; then
			sed -i.bak "/java.extended.properties/s/$/ ${BW_JAVA_OPTS}/" $bwappnodeTRA
			print_Debug "Appended $BW_JAVA_OPTS to java.extend.properties"
		fi
	fi

	if [[ ${BW_ENGINE_THREADCOUNT} ]]; then
		if [ -e ${appnodeConfigFile} ]; then
			printf '%s\n' "bw.engine.threadCount=$BW_ENGINE_THREADCOUNT" >> $appnodeConfigFile
			print_Debug "set BW_ENGINE_THREADCOUNT to $BW_ENGINE_THREADCOUNT"
		fi
	fi
	if [[ ${BW_ENGINE_STEPCOUNT} ]]; then
		if [ -e ${appnodeConfigFile} ]; then
			printf '%s\n' "bw.engine.stepCount=$BW_ENGINE_STEPCOUNT" >> $appnodeConfigFile
			print_Debug "set BW_ENGINE_STEPCOUNT to $BW_ENGINE_STEPCOUNT"
		fi
	fi
	if [[ ${BW_APPLICATION_JOB_FLOWLIMIT} ]]; then
		if [ -e ${appnodeConfigFile} ]; then
			printf '%s\n' "bw.application.job.flowlimit.$bwBundleAppName=$BW_APPLICATION_JOB_FLOWLIMIT" >> $appnodeConfigFile
			print_Debug "set BW_APPLICATION_JOB_FLOWLIMIT to $BW_APPLICATION_JOB_FLOWLIMIT"
		fi
	fi
	if [[ ${BW_APP_MONITORING_CONFIG} ]]; then
		if [ -e ${appnodeConfigFile} ]; then
			sed -i 's/bw.frwk.event.subscriber.metrics.enabled=false/bw.frwk.event.subscriber.metrics.enabled=true/g' $appnodeConfigFile
			print_Debug "set bw.frwk.event.subscriber.metrics.enabled to true"
		fi
	fi

	if [[  $BW_LOGLEVEL = "DEBUG" ]]; then
		if [[ ${BW_APPLICATION_JOB_FLOWLIMIT} ]] || [[ ${BW_ENGINE_STEPCOUNT} ]] || [[ ${BW_ENGINE_THREADCOUNT} ]] || [[ ${BW_APP_MONITORING_CONFIG} ]]; then
		echo "---------------------------------------"
		cat $appnodeConfigFile
		echo "---------------------------------------"
		fi
	fi
}

checkPlugins()
{
	pluginFolder=/resources/addons/plugins
	if [ -d ${pluginFolder} ] && [ "$(ls $pluginFolder)" ]; then 
		print_Debug "Adding Plug-in Jars"
		echo -e "name=Addons Factory\ntype=bw6\nlayout=bw6ext\nlocation=$BWCE_HOME/tibco.home/addons" > `echo $BWCE_HOME/tibco.home/bw*/*/ext/shared`/addons.link

		for name in $(find $pluginFolder -type f); 
		do	
			# filter out hidden files
			if [[ "$(basename $name )" != .* ]]; then
		   		unzip -q -o $name -d $BWCE_HOME/plugintmp/
				mkdir -p $BWCE_HOME/tibco.home/addons/runtime/plugins/ && mv $BWCE_HOME/plugintmp/runtime/plugins/* "$_"
				mkdir -p $BWCE_HOME/tibco.home/addons/bin/ && mv $BWCE_HOME/plugintmp/bin/* "$_" 2> /dev/null || true
				rm -rf $BWCE_HOME/plugintmp/
				#mkdir -p $BWCE_HOME/tibco.home/addons/lib/ && mv lib/* "$_"/${name##*/}.ini
			fi
		done
	fi
}

checkLibs()
{
	BW_VERSION=`ls $BWCE_HOME/tibco.home/bw*/`
	libFolder=/resources/addons/lib
	if [ -d ${libFolder} ] && [ "$(ls $libFolder)" ]; then
		print_Debug "Adding additional libs"
		for name in $(find $libFolder -type f); 
		do	
			if [[ "$(basename $name)" = 'libsunec.so' ]]; then 
				print_Debug "libsunec.so File found..."		
				JRE_VERSION=`ls $BWCE_HOME/tibco.home/tibcojre64/`
				JRE_LOCATION=$BWCE_HOME/tibco.home/tibcojre64/$JRE_VERSION
				SUNEC_LOCATION=$JRE_LOCATION/lib/amd64
				cp -vf $name $SUNEC_LOCATION
			else
				# filter out hidden files
				if [[  "$(basename $name )" != .* ]]; then
					mkdir -p $BWCE_HOME/tibco.home/addons/lib/ 
   					unzip -q $name -d $BWCE_HOME/tibco.home/addons/lib/ 
   				fi
			fi
		done
	fi
}

checkCerts()
{
	certsFolder=/resources/addons/certs
	if [ -d ${certsFolder} ] && [ "$(ls $certsFolder)" ]; then 
		JRE_VERSION=`ls $BWCE_HOME/tibco.home/tibcojre64/`
		JRE_LOCATION=$BWCE_HOME/tibco.home/tibcojre64/$JRE_VERSION
		certsStore=$JRE_LOCATION/lib/security/cacerts
		chmod +x $JRE_LOCATION/bin/keytool
		for name in $(find $certsFolder -type f); 
		do	
			# filter out hidden files
			if [[ "$(basename $name )" != .* && "$(basename $name )" != *.jks ]]; then
				certsFile=$(basename $name )
 			 	print_Debug "Importing $certsFile into java truststore"
  				aliasName="${certsFile%.*}"
				$JRE_LOCATION/bin/keytool -import -trustcacerts -keystore $certsStore -storepass changeit -noprompt -alias $aliasName -file $name
			fi
		done
	fi
}

checkAgents()
{
	agentFolder=/resources/addons/monitor-agents

	if [ -d ${agentFolder} ] && [ "$(ls $agentFolder)" ]; then 
		print_Debug "Adding monitoring jars"

		for name in $(find $agentFolder -type f); 
do	
	# filter out hidden files
	if [[  "$(basename $name )" != .* ]];then
		mkdir -p $BWCE_HOME/agent/
   		unzip -q $name -d $BWCE_HOME/agent/
	fi
done
		
	fi

}

memoryCalculator()
{
	if [[ ${MEMORY_LIMIT} ]]; then
		memory_Number=`echo $MEMORY_LIMIT | sed 's/m$//I'`
		configured_MEM=$((($memory_Number*67+50)/100))
		thread_Stack=$((memory_Number))
		JAVA_PARAM="-Xmx"$configured_MEM"M -Xms128M -Xss512K"
		export BW_JAVA_OPTS=$JAVA_PARAM" "$BW_JAVA_OPTS
	fi
}

checkJMXConfig()
{
	if [[ ${BW_JMX_CONFIG} ]]; then
		if [[ $BW_JMX_CONFIG == *":"* ]]; then
			JMX_HOST=${BW_JMX_CONFIG%%:*}
			JMX_PORT=${BW_JMX_CONFIG#*:}
		else
			JMX_HOST="127.0.0.1"
			JMX_PORT=$BW_JMX_CONFIG
		fi
		JMX_PARAM="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port="$JMX_PORT" -Dcom.sun.management.jmxremote.rmi.port="$JMX_PORT" -Djava.rmi.server.hostname="$JMX_HOST" -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.local.only=false "
		export BW_JAVA_OPTS=$BW_JAVA_OPTS" "$JMX_PARAM
	fi
}

checkJavaGCConfig()
{
	if [[ ${BW_JAVA_GC_OPTS}  ]]; then
 		print_Debug $BW_JAVA_GC_OPTS
 	else
 		export BW_JAVA_GC_OPTS="-XX:+UseG1GC"
 	fi
}

checkJAVAHOME()
{
		if [[ ${JAVA_HOME}  ]]; then
 			print_Debug $JAVA_HOME
 		else
 			export JAVA_HOME=$BWCE_HOME/tibco.home/tibcojre64/1.8.0
 		fi
}

checkThirdPartyInstallations()
{
	installFolder=/resources/addons/thirdparty-installs
	if [ -d ${installFolder} ] && [ "$(ls $installFolder)"  ]; then
		mkdir -p $BWCE_HOME/tibco.home/thirdparty-installs
		for f in "$installFolder"/*; do
      		if [ -d $f ]
      		then
                cp -R "$f" $BWCE_HOME/tibco.home/thirdparty-installs
      		else
              	if [ "${f##*.}" == "zip" ]       
              	then
                    unzip -q "$f" -d $BWCE_HOME/tibco.home/thirdparty-installs/$(basename "$f" .zip);
                else
                   echo "Can not unzip $f. Not a valid ZIP file"    
              	fi
      		fi
		done;
	fi	
}

setupThirdPartyInstallationEnvironment() 
{
	INSTALL_DIR=$BWCE_HOME/tibco.home/thirdparty-installs
	if [ -d "$INSTALL_DIR" ]; then
		for f in "$INSTALL_DIR"/*; do
      		if [ -d $f ]
      		then
            	if [ -d "$f"/lib ]; then
                	export LD_LIBRARY_PATH="$f"/lib:$LD_LIBRARY_PATH
            	fi	
      		
      			setupFile=`ls "$f"/*.sh`
      			if [ -f "$setupFile" ]; then
      		    	chmod 755 "$setupFile" 
      		    	source "$setupFile" "$f"
      			fi	
      		fi
		done;
	fi
}

appnodeConfigFile=$BWCE_HOME/tibco.home/bw*/*/config/appnode_config.ini
POLICY_ENABLED="false"
checkJAVAHOME
checkJMXConfig
checkJavaGCConfig

if [ ! -d $BWCE_HOME/tibco.home ];
then
	unzip -qq /resources/bwce-runtime/bwce*.zip -d $BWCE_HOME
	rm -rf /resources/bwce-runtime/bwce*.zip 2> /dev/null
	chmod 755 $BWCE_HOME/tibco.home/bw*/*/bin/startBWAppNode.sh
	chmod 755 $BWCE_HOME/tibco.home/bw*/*/bin/bwappnode
	chmod 755 $BWCE_HOME/tibco.home/tibcojre64/*/bin/java
	chmod 755 $BWCE_HOME/tibco.home/tibcojre64/*/bin/javac
	sed -i "s#_APPDIR_#$APPDIR#g" $BWCE_HOME/tibco.home/bw*/*/bin/bwappnode.tra
	sed -i "s#_APPDIR_#$APPDIR#g" $BWCE_HOME/tibco.home/bw*/*/bin/bwappnode
	touch $BWCE_HOME/keys.properties
	mkdir $BWCE_HOME/tmp
	addonFolder=/resources/addons
	if [ -d ${addonFolder} ]; then
		checkPlugins
		checkAgents
		checkLibs
		checkCerts
		checkThirdPartyInstallations
		jarFolder=/resources/addons/jars
		if [ -d ${jarFolder} ] && [ "$(ls $jarFolder)" ]; then
		#Copy jars to Hotfix
	  		cp -r /resources/addons/jars/* `echo $BWCE_HOME/tibco.home/bw*/*`/system/hotfix/shared
		fi
	fi
	ln -s /*.ear `echo $BWCE_HOME/tibco.home/bw*/*/bin`/bwapp.ear
	sed -i.bak "s#_APPDIR_#$BWCE_HOME#g" $BWCE_HOME/tibco.home/bw*/*/config/appnode_config.ini
	unzip -qq `echo $BWCE_HOME/tibco.home/bw*/*/bin/bwapp.ear` -d /tmp
	setLogLevel
	memoryCalculator
	checkEnvSubstituteConfig
fi

checkProfile
checkPolicy
setupThirdPartyInstallationEnvironment

if [ -f /*.substvar ]; then
	cp -f /*.substvar $BWCE_HOME/tmp/pcf.substvar # User provided profile
else
	cp -f /tmp/META-INF/$BW_PROFILE $BWCE_HOME/tmp/pcf.substvar
fi

$JAVA_HOME/bin/java -cp `echo $BWCE_HOME/tibco.home/bw*/*/system/shared/com.tibco.bwce.profile.resolver_*.jar`:`echo $BWCE_HOME/tibco.home/bw*/*/system/shared/com.tibco.tpcl.com.fasterxml.jackson_*`/*:`echo $BWCE_HOME/tibco.home/bw*/*/system/shared/com.tibco.bw.tpcl.org.codehaus.jettison_*`/*:$BWCE_HOME:$JAVA_HOME/lib -DBWCE_APP_NAME=$bwBundleAppName com.tibco.bwce.profile.resolver.Resolver

STATUS=$?
if [ $STATUS == "1" ]; then
    exit 1 # terminate and indicate error
fi
