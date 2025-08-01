#!/bin/bash
#
# Copyright 2012 - 2016 by TIBCO Software Inc. 
# All rights reserved.
#
# This software is confidential and proprietary information of
# TIBCO Software Inc.
#
#Use this setup.sh script to unzip the bwce-runitme zip while creating the base image.

#Variables coming from TCI scripts
TCI_BW_EDITION=$1
TCI_HOME=$2
CLOUD_VERSION=$3
BWCE_HOME=$4

echo "INFO Variables received :" $TCI_BW_EDITION, $TCI_HOME, $CLOUD_VERSION, $BWCE_HOME

print_Debug()
{
		if [[ ${BW_LOGLEVEL} && "${BW_LOGLEVEL,,}" = "debug" ]]; then
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

		for bwVarName in $(find $BUILD_DIR -path $BUILD_DIR/tibco.home -prune -o -type f -iname "*.jar");
		do
			if [[ $bwVarName == *.jar ]]; then
				mkdir -p $BUILD_DIR/temp 
				unzip -o -q $bwVarName -d $BUILD_DIR/temp
				MANIFESTMF=$BUILD_DIR/temp/META-INF/MANIFEST.MF

				bwcePolicyStr=`tr -d '\n\r ' < ${MANIFESTMF} | grep -E 'bw.authxml|bw.cred|bw.ldap|bw.wss|bw.dbauth|bw.kerberos|bw.realmdb|bw.ldaprealm|bw.userid'`
				policy_res=$?
				rm -rf $BUILD_DIR/temp

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

	if [ -z ${BW_PROFILE:=${defaultProfile}} ]; then echo "BW_PROFILE is unset. Set it to $defaultProfile"; 
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

	if [[ ${CUSTOM_LOGBACK} ]]; then
	         logback_custom=/resources/addons/custom-logback/logback.xml
		 if [ -e ${logback_custom} ]; then
			cp ${logback} `ls $logback`.original.bak && cp -f ${logback_custom}  ${logback}  
			echo "Using Custom Logback file"
		else
			echo "Custom Logback file not found. Using the default logback file"
		fi	
	fi

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
	if [ -e ${appnodeConfigFile} ]; then
		printf '%s\n' "bw.shutdown.system.onstartfailed=true" >> $appnodeConfigFile
		print_Debug "set bw.shutdown.system.onstartfailed to true"
	fi

	if [[ ${BW_JAVA_OPTS} ]]; then
		if [ -e ${bwappnodeTRA} ]; then
			sed -i.bak "/java.extended.properties/s/$/ ${BW_JAVA_OPTS}/" $bwappnodeTRA 2> /dev/null
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
	if [[ ${BW_COMPONENT_JOB_FLOWLIMIT} ]]; then
		if [ -e ${appnodeConfigFile} ]; then
			IFS=';' # space is set as delimiter
			read -ra processConfigurationList <<< "${BW_COMPONENT_JOB_FLOWLIMIT}" # str is read into an array as tokens separated by IFS
			for process in "${processConfigurationList[@]}"; do # access each element of array
				echo "Setting flow limit for $process"
				IFS=':' # space is set as delimiter
				read -ra processConfiguration <<< "$process" # str is read into an array as tokens separated by IFS
				printf '%s\n' "bw.application.job.flowlimit.$bwBundleAppName.${processConfiguration[0]}=${processConfiguration[1]}" >> $appnodeConfigFile
				print_Debug "set bw.application.job.flowlimit.$bwBundleAppName.${processConfiguration[0]} to ${processConfiguration[1]}"
			done			
		fi
	fi

	# Otel env vars
	if [[ ${BW_OTEL_ENABLED} ]]; then
		if [ -e ${appnodeConfigFile} ]; then
			printf '%s\n' "bw.engine.opentelemetry.enable=$BW_OTEL_ENABLED" >> $appnodeConfigFile
			printf '%s\n' "bw.engine.opentelemetry.metric.enable=$BW_OTEL_ENABLED" >> $appnodeConfigFile
			print_Debug "set bw.engine.opentelemetry.enable to $BW_OTEL_ENABLED"
			print_Debug "set bw.engine.opentelemetry.metric.enable to $BW_OTEL_ENABLED"
		fi
	fi

	if [[ ${BW_OTEL_AUTOCONFIGURED_ENABLED} ]]; then
		if [ -e ${appnodeConfigFile} ]; then
			printf '%s\n' "bw.opentelemetry.autoConfigured=$BW_OTEL_AUTOCONFIGURED_ENABLED" >> $appnodeConfigFile
			print_Debug "set bw.opentelemetry.autoConfigured to $BW_OTEL_AUTOCONFIGURED_ENABLED"
		fi
	fi

	if [[ ${BW_OTEL_TRACES_ENABLED} ]]; then
		if [ -e ${appnodeConfigFile} ]; then
			printf '%s\n' "bw.engine.opentelemetry.trace.enable=$BW_OTEL_TRACES_ENABLED" >> $appnodeConfigFile
			print_Debug "set bw.engine.opentelemetry.trace.enable to $BW_OTEL_TRACES_ENABLED"
		fi
	fi
	
	if [[ ${BW_APP_MONITORING_CONFIG} || ( ${TCI_HYBRID_AGENT_HOST} && ${TCI_HYBRID_AGENT_PORT}) ]]; then
		if [ -e ${appnodeConfigFile} ]; then
			sed -i 's/bw.frwk.event.subscriber.metrics.enabled=false/bw.frwk.event.subscriber.metrics.enabled=true/g' $appnodeConfigFile
			print_Debug "set bw.frwk.event.subscriber.metrics.enabled to true"
		fi
	fi

	if [[ ${TCI_HYBRID_AGENT_HOST} ]] && [[ ${TCI_HYBRID_AGENT_PORT} ]]; then
		if [ -e ${appnodeConfigFile} ]; then
			printf '%s\n' "bw.frwk.event.subscriber.instrumentation.enabled=true" >> $appnodeConfigFile
			print_Debug "set bw.frwk.event.subscriber.instrumentation.enabled to true"
		fi
	fi

	if [[ ${BW_OSGI_SSH_PORT} ]]; then
		if [ -e ${appnodeConfigFile} ]; then
			sed -i "s/osgi.console.ssh=.*/osgi.console.ssh=${BW_OSGI_SSH_PORT}/"  $appnodeConfigFile
			print_Debug "set BW_OSGI_SSH_PORT to $BW_OSGI_SSH_PORT"
		fi
	fi

	if [[ ${BW_OSGI_SERVICE_PORT} ]]; then
		if [ -e ${appnodeConfigFile} ]; then
  			sed -i "s/org.osgi.service.http.port=.*/org.osgi.service.http.port=${BW_OSGI_SERVICE_PORT}/"  $appnodeConfigFile
  			print_Debug "set BW_OSGI_SERVICE_PORT to $BW_OSGI_SERVICE_PORT"
 		fi
	fi

	if [[ ${BW_REST_DOCAPI_PORT} ]]; then
		if [ -e ${appnodeConfigFile} ]; then
				sed -i "s/bw.rest.docApi.port=.*/bw.rest.docApi.port=${BW_REST_DOCAPI_PORT}/"  $appnodeConfigFile
				print_Debug "set BW_REST_DOCAPI_PORT to $BW_REST_DOCAPI_PORT"        
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
		
		if [ $TCI_BW_EDITION != "ipaas" ]; then
			HOME=$BWCE_HOME/tibco.home
		else
			HOME=$TCI_HOME/ext/shared
		fi
		
		echo -e "name=Addons Factory\ntype=bw6\nlayout=bw6ext\nlocation=$HOME/addons" > `echo $BWCE_HOME/tibco.home/bw*/*/ext/shared`/addons.link					
		for bwVarName in $(find $pluginFolder -type f); 
		do	
			# filter out hidden files
			if [[  "$(basename $bwVarName )" != .* ]];then
				unzip -q -o $bwVarName -d $BWCE_HOME/plugintmp/
				mkdir -p $HOME/addons/runtime/plugins/ && mv $BWCE_HOME/plugintmp/runtime/plugins/* "$_"
                		mkdir -p $HOME/addons/lib/ && mv $BWCE_HOME/plugintmp/lib/*.ini "$_"${bwVarName##*/}.ini
				mkdir -p $HOME/addons/lib/ && mv $BWCE_HOME/plugintmp/lib/*.jar "$_" 2> /dev/null || true
				mkdir -p $HOME/addons/bin/ && mv $BWCE_HOME/plugintmp/bin/* "$_" 2> /dev/null || true
				if [ $TCI_BW_EDITION != "ipaas" ]; then
					find  $BWCE_HOME/plugintmp/*  -type d ! \( -name "runtime" -o -name "bin" -o -name "lib" \)  -exec mv {} /tmp \; 2> /dev/null
				else
					find  $BWCE_HOME/plugintmp/*  -type d ! \( -name "runtime" -o -name "bin" -o -name "lib" \)  -exec mv {} /opt/tibco \; 2> /dev/null
				fi
				rm -rf $BWCE_HOME/plugintmp/
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
		for bwVarName in $(find $libFolder -type f); 
		do	
			if [[ "$(basename $bwVarName)" = 'libsunec.so' ]]; then 
				print_Debug "libsunec.so File found..."		
				JRE_VERSION=`ls $BWCE_HOME/tibco.home/tibcojre64/`
				JRE_LOCATION=$BWCE_HOME/tibco.home/tibcojre64/$JRE_VERSION
				SUNEC_LOCATION=$JRE_LOCATION/lib/amd64
				cp -vf $bwVarName $SUNEC_LOCATION
			else
				# filter out hidden files
				if [[  "$(basename $bwVarName )" != .* ]]; then
					mkdir -p $BWCE_HOME/tibco.home/addons/lib/ 
   					unzip -q $bwVarName -d $BWCE_HOME/tibco.home/addons/lib/ 
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
		for bwVarName in $(find $certsFolder -type f); 
		do	
			# filter out hidden files
			if [[ "$(basename $bwVarName )" != .* && "$(basename $bwVarName )" != *.jks ]]; then
				certsFile=$(basename $bwVarName )
 			 	print_Debug "Importing $certsFile into java truststore"
  				aliasName="${certsFile%.*}"
				$JRE_LOCATION/bin/keytool -import -trustcacerts -keystore $certsStore -storepass changeit -noprompt -alias $aliasName -file $bwVarName
			fi
		done
	fi
}

checkAgents()
{
	agentFolder=/resources/addons/monitor-agents
	if [ -d ${agentFolder} ] && [ "$(ls $agentFolder)" ]; then 
		print_Debug "Adding monitoring jars"
		for bwVarName in $(find $agentFolder -type f); 
		do	
			# filter out hidden files
			if [[  "$(basename $bwVarName )" != .* ]];then
				mkdir -p $BWCE_HOME/agent/
				unzip -q $bwVarName -d $BWCE_HOME/agent/
			fi
		done
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
		export JAVA_HOME=$BWCE_HOME/tibco.home/tibcojre64/17
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

overrideBWLoggers() {
	logback=$(find $BWCE_HOME -path "$BWCE_HOME/tibco.home/bw*/*/config/logback.xml" -type f 2>/dev/null | head -n 1)
   
	if [[ ${BW_LOGGER_OVERRIDES} ]]; then
		print_Debug "Updating the loggers as provided in BW_LOGGERS_OVERRIDES"
		for override in $BW_LOGGER_OVERRIDES; do
			if [[ "$override" != *=* ]]; then
				echo "Skipping invalid format '$override'. Expected format: logger_name=level"
				continue
			fi

			logger_name=$(echo "$override" | cut -d'=' -f1 | xargs)  # Trim spaces
			log_level=$(echo "$override" | cut -d'=' -f2 | tr '[:lower:]' '[:upper:]' | xargs)
			print_Debug " Updating the logger $logger_name to $log_level"

			if [ "$logger_name" == "root" ]; then
				if grep -q "<root level=" "$logback"; then
					sed -i "s|<root level=\"[^\"]*\"|<root level=\"$log_level\"|" "$logback"
				else
					echo "Root logger not found in '$logback'. Skipping."
				fi
				continue
			fi

			# Check if logger exists and update it else add a new logger
			if grep -q "<logger name=\"$logger_name\"" "$logback"; then
			# Check if <level> exists within the logger block update it else insert level if missing
				if sed -n "/<logger name=\"$logger_name\"/,/<\/logger>/p" "$logback" | grep -q "<level "; then
					sed -i "/<logger name=\"$logger_name\"/,/<\/logger>/s|<level[^>]*>|<level value=\"$log_level\"/>|" "$logback"
				else
					sed -i "/<logger name=\"$logger_name\"/a \ \ \ \ <level value=\"$log_level\"/>" "$logback"
				fi
			else
 				sed -i "/<\/configuration>/i \ \ \ \ <logger name=\"$logger_name\">\n \ \ \ \ \ \ <level value=\"$log_level\"/>\n \ \ \ \ </logger>" "$logback"
			fi
	 done
   fi
}


appnodeConfigFile=$BWCE_HOME/tibco.home/bw*/*/config/appnode_config.ini
POLICY_ENABLED="false"
checkJAVAHOME
checkJMXConfig
checkJavaGCConfig

if [ -d $BWCE_HOME/tibco.home ];
then
	chmod 755 $BWCE_HOME/tibco.home/bw*/*/bin/startBWAppNode.sh
	chmod 755 $BWCE_HOME/tibco.home/bw*/*/bin/bwappnode
	chmod 755 $BWCE_HOME/tibco.home/tibcojre64/*/bin/java
	chmod 755 $BWCE_HOME/tibco.home/tibcojre64/*/lib/jspawnhelper
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
	if [ $TCI_BW_EDITION != "ipaas" ]; then
		ln -s /*.ear `echo $BWCE_HOME/tibco.home/bw*/*/bin`/bwapp.ear
		sed -i.bak "s#_APPDIR_#$BWCE_HOME#g" $BWCE_HOME/tibco.home/bw*/*/config/appnode_config.ini
		unzip -qq `echo $BWCE_HOME/tibco.home/bw*/*/bin/bwapp.ear` -d /tmp
		setLogLevel		
	fi
fi
export BW_OPTS=' --add-opens java.management/sun.management=ALL-UNNAMED --add-opens=java.base/jdk.internal.loader=ALL-UNNAMED --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.lang.reflect=ALL-UNNAMED --add-opens java.naming/com.sun.jndi.ldap=ALL-UNNAMED --add-exports java.base/sun.security.ssl=ALL-UNNAMED --add-exports java.base/com.sun.crypto.provider=ALL-UNNAMED --add-exports java.management/com.sun.jmx.mbeanserver=ALL-UNNAMED '
export BW_JAVA_OPTS="$BW_JAVA_OPTS $BW_OPTS"

if [ $TCI_BW_EDITION != "ipaas" ]; then
	export BW_OPTS=' --add-opens java.management/sun.management=ALL-UNNAMED --add-opens=java.base/jdk.internal.loader=ALL-UNNAMED --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.lang.reflect=ALL-UNNAMED --add-opens java.naming/com.sun.jndi.ldap=ALL-UNNAMED --add-exports java.base/sun.security.ssl=ALL-UNNAMED --add-exports java.base/com.sun.crypto.provider=ALL-UNNAMED --add-exports java.management/com.sun.jmx.mbeanserver=ALL-UNNAMED '
	export BW_JAVA_OPTS="$BW_JAVA_OPTS $BW_OPTS"
	overrideBWLoggers
	checkEnvSubstituteConfig
	checkProfile	
	checkPolicy
	setupThirdPartyInstallationEnvironment
	
	if [ -f /$BW_PROFILE ]; then
		cp -f /$BW_PROFILE $BWCE_HOME/tmp/pcf.substvar # User provided profile
	else
		cp -f /tmp/META-INF/$BW_PROFILE $BWCE_HOME/tmp/pcf.substvar
	fi
$JAVA_HOME/bin/java $BW_OPTS -cp `echo $BWCE_HOME/tibco.home/bw*/*/system/shared/com.tibco.bwce.profile.resolver_*.jar`:`echo $BWCE_HOME/tibco.home/bw*/*/system/shared/com.tibco.security.tibcrypt_*.jar`:`echo $BWCE_HOME/tibco.home/bw*/*/system/shared/com.tibco.tpcl.com.fasterxml.jackson_*`/*:`echo $BWCE_HOME/tibco.home/bw*/*/system/shared/com.tibco.bw.tpcl.encryption.util_*`/lib/*:`echo $BWCE_HOME/tibco.home/bw*/*/system/shared/com.tibco.bw.tpcl.org.codehaus.jettison_*`/*:`echo $BWCE_HOME/tibco.home/bw*/*/system/shared/com.tibco.tpcl.logback_*`/*:$BWCE_HOME:$JAVA_HOME/lib -DBWCE_APP_NAME=$bwBundleAppName  com.tibco.bwce.profile.resolver.Resolver 1>/dev/null 2>&1
STATUS=$?
	if [ $STATUS == "1" ]; then
		exit 1 # terminate and indicate error
	fi
fi

if [ $TCI_BW_EDITION == "ipaas" ];
then
    echo "$(date "+%H:%M:%S.000") INFO ######################## Setting up TCI environment start #######################"
	tci_java_home="/usr/lib/jvm/java"
	BW_VERSION=`ls $BWCE_HOME/tibco.home/bw*/`
    
	#copy runtime zip in TCI_HOME	
	if [ -d $BWCE_HOME/tibco.home/bwce/${BW_VERSION} ]; then
		yes | cp -r $BWCE_HOME/tibco.home/bwce/${BW_VERSION}/* $TCI_HOME
	fi
	if [ -d $BWCE_HOME/tibco.home/addons/lib ]; then
		yes | cp -r $BWCE_HOME/tibco.home/addons/lib $TCI_HOME/ext/shared
	fi

	echo "$(date "+%H:%M:%S.000") INFO Copied runtime zip in TCI home: " $TCI_HOME
    
	#Modify TRA files to use new TCI home = /opt/tibco/bwcloud/<cloudversion>
	cd $TCI_HOME/bin
		
	#TODO: check without tra modification
	#Modify bwappnode & bwappnode.tra file in runtime zip
	#echo -e "\nexport TIBCO_JAVA_HOME=${tci_java_home} \ntibco.include.tra=${TCI_HOME}/bin/bwcommon.tra" >> bwappnode
	sed -i "s+$APPDIR/tibco.home+/opt/tibco+g" bwappnode
	sed -i "s+bwce/${BW_VERSION}+bwcloud/${CLOUD_VERSION}+g" bwappnode 
	
	#Change paths in bwcommon.tra file. check if FTL home need to be added in the path
	sed -i "s+%APPDIR%/tibco.home+/opt/tibco+g" bwcommon.tra
	sed -i "s+tibco.product.folder=bwce/${BW_VERSION}+tibco.product.folder=bwcloud/${CLOUD_VERSION}+g" bwcommon.tra 
	sed -i 's+tibco.env.product.type=bwce+tibco.env.product.type=bwcloud+g' bwcommon.tra
	
	#Modify appnode_config.ini
	sed -i 's+osgi.console.ssh=1122+osgi.console=1122+g' $TCI_HOME/config/appnode_config.ini
	sed -i 's+osgi.console.enable.builtin=false+# osgi.console.enable.builtin=false+g' $TCI_HOME/config/appnode_config.ini
	sed -i 's+osgi.console.ssh.useDefaultSecureStorage=true+# osgi.console.ssh.useDefaultSecureStorage=true+g' $TCI_HOME/config/appnode_config.ini
	sed -i "s+java.security.auth.login.config=_APPDIR_/tibco.home/bwce/${BW_VERSION}/config/equinox.console.jass.login.conf+# java.security.auth.login.config=_APPDIR_/tibco.home/bwce/${BW_VERSION}/config/equinox.console.jass.login.conf+g" $TCI_HOME/config/appnode_config.ini
	sed -i "s+ssh.server.keystore=_APPDIR_/tibco.home/bwce/${BW_VERSION}/repo/hostkey.ser+# ssh.server.keystore=_APPDIR_/tibco.home/bwce/${BW_VERSION}/repo/hostkey.ser+g" $TCI_HOME/config/appnode_config.ini
	sed -i "s+org.eclipse.equinox.console.jaas.file=_APPDIR_/tibco.home/bwce/${BW_VERSION}/repo/store+# org.eclipse.equinox.console.jaas.file=_APPDIR_/tibco.home/bwce/${BW_VERSION}/repo/store+g" $TCI_HOME/config/appnode_config.ini
	sed -i 's+org.eclipse.equinox.http.jetty.autostart=true+# org.eclipse.equinox.http.jetty.autostart=true+g' $TCI_HOME/config/appnode_config.ini
	sed -i 's+bw.frwk.event.subscriber.metrics.enabled=false+# bw.frwk.event.subscriber.metrics.enabled=false+g' $TCI_HOME/config/appnode_config.ini
	sed -i 's+_APPDIR_/tibco.home+/opt/tibco+g' $TCI_HOME/config/appnode_config.ini
	
	#Clean up
	rm -rf $TCI_HOME/bin/startBWAppNode.sh
    rm -rf $TCI_HOME/bin/bwappnode.script.sh
	rm -rf $TCI_HOME/bin/bwappnode.tra
	echo "$(date "+%H:%M:%S.000") INFO ######################## Setting up TCI environment end #######################"
	
fi

