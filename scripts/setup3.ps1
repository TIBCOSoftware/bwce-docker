function print_Debug( $message ) {

	if ( -not [String]::IsNullOrEmpty($BW_LOGLEVEL) -and $BW_LOGLEVEL.toLower() -eq "debug" ) {
	
		write-host $message
	
	}

}

function checkJAVAHOME{

	echo "this functions was called also called"

    if ( -not [String]::IsNullOrEmpty($JAVA_HOME) ) {
	
        print_Debug($JAVA_HOME)
		
    } else {
	
        SET JAVA_HOME=$env:BWCE_HOME\tibco.home\tibcojre64\1.8.0
		
    }
	
}

function checkJavaGCConfig {

	echo "this functions was called"

    if ( -not [String]::IsNullOrEmpty($BW_JAVA_GC_OPTS) ) {
	
         print_Debug($BW_JAVA_GC_OPTS)
		 
    } else {
	
        SET BW_JAVA_GC_OPTS="-XX:+UseG1GC"
		
    }

}



$appnodeConfigFile=$env:BWCE_HOME/tibco.home/bw*/*/config/appnode_config.ini
$POLICY_ENABLED="false"
checkJAVAHOME
#checkJMXConfig
checkJavaGCConfig

