::ECHO OFF
SET BWCE_HOME=c:/tmp
SET APPDIR=%BWCE_HOME%
SET MALLOC_ARENA_MAX=2
SET MALLOC_MMAP_THRESHOLD_=1024
SET MALLOC_TRIM_THRESHOLD_=1024
SET MALLOC_MMAP_MAX_=65536
SET BW_KEYSTORE_PATH=C:\bwce\bwce-docker\resources\addons\certs
CALL C:\scripts\setup.bat

STATUS=ERRORLEVEL
if %STATUS% == "1" 
	ECHO "ERROR: Failed to setup BWCE runtime. See logs for more details." 
	exit 1
:: exec bash $BWCE_HOME/tibco.home/bw*/*/bin/startBWAppNode.sh
c:/tmp/tibco.home/bwce/2.3/bin/bwappnode.exe --propFile c:/tmp/tibco.home/bwce/2.3/bin/bwappnode.tra -profileFile c:/tmp/tmp/pcf.substvar  -ear c:/tmp/tibco.home/bwce/2.3/bin/bwapp.ear -config c:/tmp/tibco.home/bwce/2.3/config/appnode_config.ini -l admin startlocal