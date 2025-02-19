#!/bin/bash
#
# Copyright 2012 - 2025 by TIBCO Software Inc. 
# All rights reserved.
#
# This software is confidential and proprietary information of
# TIBCO Software Inc.
#

export ARTIFACTS_LOC="/app/artifacts"
logLocation="/app/logs/${HOSTNAME}/bwapp/otel.log"

print_Info()
{
	   echo "$(date "+%Y-%m-%dT%H:%M:%S,%3N") INFO $1"
 		echo "$(date "+%Y-%m-%dT%H:%M:%S,%3N") INFO $1"   >> $logLocation
}

print_Error()
{
	   echo "$(date "+%Y-%m-%dT%H:%M:%S,%3N") ERROR $1"
 		echo "$(date "+%Y-%m-%dT%H:%M:%S,%3N") ERROR $1"   >> $logLocation
}

prepareContribs() {
   print_Info "Loading contributions for BW engine... [ref:$HOSTNAME]"

   bw_contribs_src=${ARTIFACTS_LOC}/contribs
   bw_supplements_src=${ARTIFACTS_LOC}/supplements
   usePlugin=false
   if [ -d "$bw_contribs_src" ]; then
	   if [ "$(ls -A $bw_contribs_src)" ]; then
         usePlugin=true
	   fi
   fi

   if [ "$usePlugin" = false ] ; then
      print_Info "No contributions found... [ref:$HOSTNAME]"
		return
   fi

   useSupplement=false
   if [ -d "$bw_supplements_src" ]; then
	   if [ "$(ls -A $bw_supplements_src)" ]; then
         useSupplement=true
	   fi
   fi

   if [ "$useSupplement" = false ] ; then
      print_Info "No supplements found... [ref:$HOSTNAME]"
   fi

   for entry in "$bw_contribs_src"/*; do
      el=$(basename "$entry")
      # echo "$(date "+%Y-%m-%dT%H:%M:%S,%3N") INFO %%%%% Preparing contribution: $el [ref:$HOSTNAME]"

      # copying the plugin zip file

      if [ "$el" != "ems" ] && [ "$el" != "customdriver" ] && [ "$el" != "customplugin" ] && [ "$el" != "oracle" ] ; then
         for zipFile in "$entry"/*.zip; do
            cp ${zipFile} ../resources/addons/plugins
            if [ -f "$entry"/contribution.json ]; then
               contribVersion=$(cat "$entry/contribution.json" | jq -c '.tag')
               contribVersion=${contribVersion//-tci-2.0/}
               print_Info "Adding Contribution: $el Version: $contribVersion [ref:$HOSTNAME]"
            fi
         done
      fi

      # read plugin contribution.json file
      if [ -f "$entry"/contribution.json ]; then 

       # Copy supplment files to destination
       if [ "$useSupplement" = true ] ; then
            fileList=$(cat "$entry/contribution.json" | jq -c '.supplement.filePaths[]?')
            required=$(cat "$entry/contribution.json" | jq -c '.supplement.required')
            for file in ${fileList[@]}; do
               name=$(jq -r '.name' <<< "$file")
               destination=$(jq -r '.destination' <<< "$file")
               if [ "$destination" == "/opt/tibco/bwcloud/1.1/system/hotfix/shared" ] ; then
                  destination="/resources/addons/jars"
               fi
               
               if [ -f "$bw_supplements_src/$el/$name" ] ; then
                  if [[ "$name" == *".zip" ]] ; then
                     print_Info "Unzipping supplement file $name to destination $destination for contribution: $el [ref:$HOSTNAME]"
                     unzip -o -q "$bw_supplements_src/$el/$name" -d "$destination"
                  else
                     print_Info "Copying supplement file $name to destination $destination for contribution: $el [ref:$HOSTNAME]"
                     cp "$bw_supplements_src/$el/$name" "$destination"
                  fi
               fi
            done
         fi

       # Set envs from contribution json file.
       envList=$(cat "$entry/contribution.json" | jq -c '.supplement.env[]?')
        for env in ${envList[@]}; do
               name=$(jq -r '.name' <<< "$env")
               value=$(jq -r '.value' <<< "$env")
               print_Info "Setting environment variable $name=$value for contribution: $el [ref:$HOSTNAME]"
               export "$name"="$value"
        done

      # set system properties from contribution json file
      sysPropsList=$(cat "$entry/contribution.json" | jq -c '.supplement.engineProperties[]?')
        for sysProp in ${sysPropsList[@]}; do
               name=$(jq -r '.name' <<< "$sysProp")
               value=$(jq -r '.value' <<< "$sysProp")
               print_Info "Setting system property $name=$value for contribution: $el [ref:$HOSTNAME]"
               #export BW_JAVA_OPTS=$BW_JAVA_OPTS:" -D$name=$value"
               appnodeConfigFile=$BWCE_HOME/tibco.home/bw*/*/config/appnode_config.ini
               printf '%s\n' "$name=$value" >> $appnodeConfigFile
        done
            
      else
         print_Error "Contribution.json file does not exist for contribution: $el [ref:$HOSTNAME]"
      fi

      # check if plugin has custom.sh file
      if [ -f "$entry"/custom.sh ]; then
         print_Info "Found custom.sh for contribution: $el [ref:$HOSTNAME]"
         source "$entry"/custom.sh
      fi 

   done

}

prepareContribs

print_Info "Artifacts transfer completed..."
print_Info "BW_BUILDTYPE_TAG: $TIBCO_INTERNAL_BW_BUILDTYPE_TAG"
print_Info "BW_BASE_IMAGE_TAG: $TIBCO_INTERNAL_BW_BASE_IMAGE_TAG"
