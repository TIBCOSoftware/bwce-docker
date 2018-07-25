#!/bin/bash
#Set ENV Variables
export BWCE_HOME=c:/tmp
export APPDIR=${BWCE_HOME}
export MALLOC_ARENA_MAX=2
export MALLOC_MMAP_THRESHOLD_=1024
export MALLOC_TRIM_THRESHOLD_=1024
export MALLOC_MMAP_MAX_=65536
export BW_KEYSTORE_PATH=c:/resources/addons/certs
export BW_HOME=c:/tmp/tibco.home/bwce/2.3
echo "********I came till here************"
. ./scripts/setup.sh
STATUS=$?
if [ $STATUS == "1" ]; then
    echo "ERROR: Failed to setup BWCE runtime. See logs for more details."
    exit 1
fi
#exec bash $BWCE_HOME/tibco.home/bw*/*/bin/startBWAppNode.sh
#CMD ["bash", "c:/scripts/start.sh"]
echo "********Printing DIR 2************"
	for entry in `ls c:/tmp/tibco.home/bwce/2.3/bin`
	do
	  echo "$entry"
	done
	echo "********Printing DIR end 2************"
cd c:/tmp/tibco.home/bwce/2.3/bin

#./bwappnode.exe --propFile ./bwappnode.tra -ear ./bwapp.ear -l admin startlocal --config c:/tmp/tibco.home/bwce/2.3/config/appnode_config.ini
c:/tmp/tibco.home/bwce/2.3/bin/bwappnode.exe --propFile c:/tmp/tibco.home/bwce/2.3/bin/bwappnode.tra -profileFile c:/tmp/tmp/pcf.substvar  -ear c:/tmp/tibco.home/bwce/2.3/bin/bwapp.ear -config c:/tmp/tibco.home/bwce/2.3/config/appnode_config.ini -l admin startlocal