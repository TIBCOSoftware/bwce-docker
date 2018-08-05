$ProgressPreference = 'SilentlyContinue'

function Print-Debug() {
	
	[CmdletBinding()]
	param( $message )
	
	process {
	
		try {
	
			if ( -not [String]::IsNullOrEmpty($env:BW_LOGLEVEL) -and $env:BW_LOGLEVEL.toLower() -eq "debug" ) {
		
				Write-Output $message
			
			}
		
		} catch {
			
			Write-Error -Exception $PSItem -ErrorAction Stop
			
		}
	
	}

}


<#function Get-ErrorInformation {
    [cmdletbinding()]
    param($incomingError)

    #if ($incomingError -and (($incomingError| Get-Member | Select-Object -ExpandProperty TypeName -Unique) -eq 'System.Management.Automation.ErrorRecord')) {
    if ($incomingError ) {

        Write-Output `n"Error information:"`n
        Write-Output `t"Exception type for catch: [$($IncomingError.Exception | Get-Member | Select-Object -ExpandProperty TypeName -Unique)]"`n 

        if ($incomingError.InvocationInfo.Line) {
        
            Write-Output `t"Command                 : [$($incomingError.InvocationInfo.Line.Trim())]"
        
        } else {

            Write-Output `t"Unable to get command information! Multiple catch blocks can do this :("`n

        }

        Write-Output `t"Exception               : [$($incomingError.Exception.Message)]"`n
        Write-Output `t"Target Object           : [$($incomingError.TargetObject)]"`n
    
    }

    Else {

        Write-Output "Please include a valid error record when using this function!" -ForegroundColor Red -BackgroundColor DarkBlue

    }

}#>



function Check-Profile {

   [cmdletbinding()]
   param() 

	try {
	
		Print-Debug("Inside CheckProfile function")

		$BUILD_DIR=$env:BWCE_HOME
		$defaultProfile="default.substvar"
		$manifest=$BUILD_DIR+"\META-INF\MANIFEST.MF"
		$bwAppConfig="TIBCO-BW-ConfigProfile"
		$bwAppNameHeader="Bundle-SymbolicName"
		$bwEdition="bwcf"
		#bwceTarget='TIBCO-BWCE-Edition-Target:'
		if ( [System.IO.File]::Exists($manifest) ) { 
			
			$bwAppProfileStr = select-string $bwAppConfig+".*.substvar" $manifest | ForEach-Object Line
			Print-Debug($bwAppProfileStr)
            $env:bwBundleAppName = select-string $bwAppNameHeader $manifest | ForEach-Object {$_.Line.Split(":")[1].Trim()}
			Print-Debug($env:bwBundleAppName)
			
			if ( $env:DISABLE_BWCE_EAR_VALIDATION -ne "True" ) {
			
				$bwEditionHeaderStr = select-string $bwEdition $manifest 
				
				if (-not [String]::IsNullOrEmpty($bwEditionHeaderStr)) {
				
					Write-Output " "
				
				} else {
				
					Write-Output "ERROR: Application $env:bwBundleAppName is not supported in TIBCO BusinessWorks Container Edition. Convert this application to TIBCO BusinessWorks Container Edition using TIBCO Business Studio Container Edition. Refer Conversion Guide for more details."
					
				}
			
			} else {
			
				Write-Output "BWCE EAR validation disabled"
			}
			
			Get-ChildItem $BUILD_DIR\tibco.home -Filter *.jar |
			ForEach-Object {
			
				$name = $_.Name
				$fileExtension = $_.Extension
                
				if ( $fileExtension -eq ".jar" ) {
				
					New-Item -Path $BUILD_DIR\temp
					#Check how to do quiet unzipping
					Expand-Archive -Path $BUILD_DIR\tibco.home\$name -DestinationPath $BUILD_DIR\temp -Force
					$MANIFESTMF= "$BUILD_DIR\temp\META-INF\MANIFEST.MF"
					#need to check if we have to handle any special cases here as well(shell script had a long command)
					$bwcePaletteStr = select-string  -Quiet 'bw.rv' $MANIFESTMF 
					
					$bwcePolicyPatternArray = "bw.authxml", "bw.cred" , "bw.ldap", "bw.wss", "bw.dbauth", "bw.kerberos", "bw.realmdb", "bw.ldaprealm", "bw.userid"
					$bwcePolicyStr = select-string  -Quiet $bwcePolicyPatternArray $MANIFESTMF
					
					#check if this condition works properly
					Remove-Item $BUILD_DIR\temp -Force -Recurse
					
					if ( $bwcePaletteStr ) {
					
						Write-Output "ERROR: Application $bwBundleAppName is using unsupported RV palette and can not be deployed in Docker. Rebuild your application for Docker using TIBCO Business Studio Container Edition."
						Exit 1
					}
					
					if ( $bwcePolicyStr ) {
						#check this boolean assignment as well, and set it globally
						$POLICY_ENABLED = "true"
						break
					
					}	
					
				}
				
				
				
			}
			
		}
		
		$bwcePolicyStringArray = $bwAppProfileStr -split "/"
		
		foreach( $individualString in $bwcePolicyStringArray ) {
        
            $defaultProfile = switch -Wildcard ( $individualString ) {
			
				'*substvar' {
				
					$individualString
				
				}
			
			}
        
        }
				
		if ( [String]::IsNullOrEmpty(($env:BW_PROFILE = $defaultProfile)) ) {
    
			Write-Output "BW_PROFILE is unset. Set it to $defaultProfile"
		
		} else {
		
			switch -Wildcard ( $env:BW_PROFILE ) {
			
			 	'*substvar' {}
				default 
				{
					$env:BW_PROFILE = "$env:BW_PROFILE.substvar"
					
				}
			
			}
		
			Write-Output "BW_PROFILE is set to '$env:BW_PROFILE'"
		}
		
		
	} catch {
	
		Write-Error -Exception $PSItem -ErrorAction Stop
        #Write-Error -Exception $PSItem -ErrorAction Stop
		#Get-ErrorInformation -incomingError $_ -ErrorAction Stop
	
	}
	

}

function Check-Policy {

    [CmdletBinding()]
	param()

	try {
	
		if ( $POLICY_ENABLED.toLower() -eq "true" ) {

            Print-Debug("Executing Check-Policy Function")
	
			if ( Test-Path -Path $appnodeConfigFile -PathType leaf ) {
			
				Add-Content -Path $appnodeConfigFile -Value "`r`nbw.governance.enabled=true"
				Print-Debug("Set bw.governance.enabled=true")
		
			}
		
		}
	
	} catch {
	
		Print-Debug("Error Setting bw.governance property to true. Check if AppNode Config file exists or not.")
		Write-Error -Exception $PSItem -ErrorAction Stop

	}
	
}

function Set-LogLevel {
    
    [CmdletBinding()]
	param()
	
    try {
		Print-Debug("Inside Set-Loglevel function")
		$logback="$env:BWCE_HOME\tibco.home\bw*\*\config\logback.xml"
		Print-Debug($env:BW_LOGLEVEL)

		if ( -not [String]::IsNullOrEmpty($env:BW_LOGLEVEL) ) {
		   
			if ( Test-Path -Path $logback -PathType leaf) {
			   
				Copy-Item $(Get-ChildItem $logback) "$(Get-ChildItem $logback).bak"
				(Get-Content $logback | ForEach-Object {$_ -ireplace "<root level\s*=.*", "<root level = `"$env:BW_LOGLEVEL`">"}) -join "`n" | Set-Content -NoNewline -Force $logback
				Write-Output "The loglevel is set to $env:BW_LOGLEVEL level"
			
			}
		
		} else {
           
			Write-Output "The loglevel is set to Error"
            Copy-Item $(Get-ChildItem $logback) "$(Get-ChildItem $logback).bak"
			(Get-Content $logback | ForEach-Object {$_ -ireplace "<root level\s*=.*", "<root level = `"ERROR`">"}) -join "`n" | Set-Content -NoNewline -Force $logback
		
		}
	
	} catch {
	
		Print-Debug("Error setting log level in logback file")
		Write-Error -Exception $PSItem -ErrorAction Stop
	
	}

}

<# function Check-EnvSubstituteConfig {

    [CmdletBinding()]
	param()
    
	try{
	
	    Write-Output "Inside checkEnvSubstituteConfig function"
        
		####Compile-Error-Came-Here-So-We-Put-Path-In_Quotes, also need to check if such paths have wildcards or not, hence, maybe we need to enclose them within quotes
		$bwappnodeTRA = "$env:BWCE_HOME\tibco.home\bw*\*\bin\bwappnode.tra"
        $appnodeConfigFile="$env:BWCE_HOME\tibco.home\bw*\*\config\appnode_config.ini"
        $manifest="c:\tmp\META-INF\MANIFEST.MF"
        $bwAppNameHeader="Bundle-SymbolicName"
        $bwBundleAppName = select-string $bwAppNameHeader $manifest | %{$_.Line.Split(":")[1]}
        $env:BWCE_APP_NAME=$bwBundleAppName      
        #TODO: How is addons_home populated(can't see it in env variables"
        if( Test-Path -Path $bwappnodeTRA -PathType leaf){
            #Copy-Item -Path $bwappnodeTRA -Destination "$bwappnodeTRA.bak" -Force -Confirm
           xcopy $appnodeConfigFile "$appnodeConfigFile.bak" /v /q
            (Get-Content $bwappnodeTRA | ForEach-Object {$_ -replace "-Djava.class.path=", "-Djava.class.path=$ADDONS_HOME/lib:"}) -join "`n" | Set-Content -NoNewline -Force $bwappnodeTRA
            print_Debug "Appended ADDONS_HOME/lib in bwappnode.tra file"
        }
        #TODO: Is appnode even needed?
        <#if(Test-Path -Path $bwappnodeFile -PathType leaf){
            Copy-Item -Path $bwappnodeFile -Destination "$bwappnodeFile.bak"
            (Get-Content $bwappnodeTRA | ForEach-Object {$_ -replace "-Djava.class.path=", "-Djava.class.path=$ADDONS_HOME/lib:"}) -join "`n" | Set-Content -NoNewline -Force $bwappnodeTRA
            print_Debug "Appended ADDONS_HOME/lib in bwappnode.tra file"
        } 
        if($env:BW_JAVA_OPTS){
            if(Test-Path -Path $bwappnodeTRA -PathType leaf){
                Copy-Item -Path $bwappnodeTRA -Destination "$bwappnodeTRA.bak"
                #sed -i.bak "/java.extended.properties/s/$/ ${BW_JAVA_OPTS}/" $bwappnodeTRA
                print_Debug "Appended $env:BW_JAVA_OPTS to java.extend.properties"
            }
        } #
        if($env:BW_ENGINE_THREADCOUNT){
            if(Test-Path -Path $appnodeConfigFile -PathType leaf){
                    Add-Content -Path $appnodeConfigFile -Value "`r`nbw.engine.threadCount=$env:BW_ENGINE_THREADCOUNT"
                    print_Debug "set BW_ENGINE_THREADCOUNT to $env:BW_ENGINE_THREADCOUNT"
            }
        }
        if($env:BW_ENGINE_STEPCOUNT){
            if(Test-Path -Path $appnodeConfigFile -PathType leaf){
                    Add-Content -Path $appnodeConfigFile -Value "`r`nbw.engine.stepCount=$env:BW_ENGINE_STEPCOUNT"
                    print_Debug "set BW_ENGINE_STEPCOUNT to $env:BW_ENGINE_STEPCOUNT"
            }
        }
        #TODO: Check the condition below, whether concatenation is happening properly or not
        if($env:BW_APPLICATION_JOB_FLOWLIMIT){
            if((Test-Path -Path $appnodeConfigFile -PathType leaf)){
                    Add-Content -Path $appnodeConfigFile -Value "`r`nbw.application.job.flowlimit.$env:bwBundleAppName=$env:BW_APPLICATION_JOB_FLOWLIMIT"
                    print_Debug "set BW_APPLICATION_JOB_FLOWLIMIT to $env:BW_APPLICATION_JOB_FLOWLIMIT"
            }
        }
        if($env:BW_APP_MONITORING_CONFIG){
            if((Test-Path -Path $appnodeConfigFile -PathType leaf)){
                (Get-Content $appnodeConfigFile | ForEach-Object {$_ -replace "bw.frwk.event.subscriber.metrics.enabled=false", "bw.frwk.event.subscriber.metrics.enabled=true"}) -join "`n" | Set-Content -NoNewline -Force $appnodeConfigFile
                print_Debug "set bw.frwk.event.subscriber.metrics.enabled to true"
            }
        }
        #Always do strict checking, in this case if step count is set to 0 & no other variable is set, condition will become false, even though the value is there
        if(-not [String]::IsNullOrEmpty($env:BW_LOGLEVEL) -and $env:BW_LOGLEVEL.toLower() -eq "debug"){
            if(-not [String]::IsNullOrEmpty($env:BW_APPLICATION_JOB_FLOWLIMIT) -or -not [String]::IsNullOrEmpty($env:BW_ENGINE_STEPCOUNT) -or -not [String]::IsNullOrEmpty($env:BW_ENGINE_THREADCOUNT) -or -not [String]::IsNullOrEmpty($env:BW_APP_MONITORING_CONFIG)){
                Write-Output "---------------------------------------"
                cat $appnodeConfigFile
                Write-Output "---------------------------------------"
			}
        }
		
    } catch {
	
        print_Debug "Error in setting environment configurations"
		Write-Error -Exception $PSItem -ErrorAction Stop
		
    }
	
} #>



<#function Check-Plugins {
	param()
	process {
	
		try {
		
			Write-Output "Inside Check-Plugins function"
			#make all paths like this dynamic
			$pluginFolder = "c:\resources\addons\plugins"
			
			if ( (Test-Path $pluginFolder) -and (Get-Item $pluginFolder -Exclude ".*").GetFileSystemInfos().Count -gt 0 ) {
			
				print_Debug("Adding Plug-in Jars")
				#check this condition 
				$addonsFilePath = "$env:BWCE_HOME\tibco.home\bw*\*\ext\shared"
				#Added quotes in path here, don't know why and not sure if addons link will be evaluated to absolute path or not
				"name=Addons Factory`r`ntype=bw6`r`nlayout=bw6ext`r`nlocation=$env:BWCE_HOME\tibco.home\addons" | Set-Content -Path $addonsFilePath\addons.link   
					
				Get-ChildItem -Attributes !Hidden $pluginFolder |
				ForEach-Object {
					$name = $_.Name
					#New-Item -Path $env:BWCE_HOME\plugintmp, also check if -force command is required here or not
					#also assuming $name contains the entire path of the file along with thee file name
					Expand-Archive -Path $name -DestinationPath $env:BWCE_HOME\plugintmp -Force
					New-Item -ItemType directory $env:BWCE_HOME\tibco.home\addons\runtime\plugins 
					Move-Item -Path $env:BWCE_HOME\plugintmp\runtime\plugins\* -Destination $env:BWCE_HOME\tibco.home\addons\runtime\plugins

                    New-Item -ItemType directory $env:BWCE_HOME\tibco.home\addons\lib
                    Move-Item -Path $env:BWCE_HOME\plugintmp\lib\*.jar -include -Destination $env:BWCE_HOME\tibco.home\addons\lib

                    New-Item -ItemType directory $env:BWCE_HOME\tibco.home\addons\bin
					Move-Item -Path $env:BWCE_HOME\plugintmp\bin -Destination $env:BWCE_HOME\tibco.home\addons\bin | Out-Null
				
				}
			
			}
	
		} catch {
		
			#Write-Error -Exception $PSItem -ErrorAction Stop
			Get-ErrorInformation -incomingError $_ -ErrorAction Stop
		
		}
	
	}


}#>


function Check-JAVAHOME {

    [CmdletBinding()]
	param()

	try {
	
		Print-Debug("Inside checkJAVAHOME function")
	
		if ( -not [String]::IsNullOrEmpty($env:JAVA_HOME) ) {
		
			Print-Debug($env:JAVA_HOME)
			
		} else {
			Print-Debug("set java home")
			$env:JAVA_HOME=$env:BWCE_HOME + "\tibco.home\tibcojre64\1.8.0"
			
		}
		
	
	} catch {
	
		#Write-Error  "Ran into an issue: $PSItem" -ErrorAction Stop
		#$pscmdlet.ThrowTerminatingError($_)
		Write-Error -Exception $PSItem -ErrorAction Stop
	
	}
	
}

function Check-JavaGCConfig {

    [CmdletBinding()]
	param()
	
	try {
	
		Print-Debug("Inside checkJavaGCConfig function")
	
		if ( -not [String]::IsNullOrEmpty($env:BW_JAVA_GC_OPTS) ) {
	
			 Print-Debug($env:BW_JAVA_GC_OPTS)
			 
		} else {
		
			$env:BW_JAVA_GC_OPTS="-XX:+UseG1GC"
			
		}
	
	} catch {
	
		Write-Error -Exception $PSItem -ErrorAction Stop
	
	}

}

function Check-JMXConfig {

    [CmdletBinding()]
	param()

	try {
	
		Print-Debug("Inside checkJMXConfig function")
	
		if ( -not [String]::IsNullOrEmpty($env:BW_JMX_CONFIG) ) {
		
			if ( $env:BW_JMX_CONFIG -like '*:*' ) {
			
				$JMX_HOST=$env:BW_JMX_CONFIG.Split(":")[0]
				$JMX_PORT=$env:BW_JMX_CONFIG.Split(":")[1]
			
			} else {
			
				$JMX_HOST="127.0.0.1"
				$JMX_PORT=$env:BW_JMX_CONFIG
			
			}
			
			$JMX_PARAM="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=$JMX_PORT -Dcom.sun.management.jmxremote.rmi.port=$JMX_PORT -Djava.rmi.server.hostname=$JMX_HOST -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.local.only=false "
			$env:BW_JAVA_OPTS="$BW_JAVA_OPTS $JMX_PARAM"
		
		}
	
	} catch {
	
		Write-Error -Exception $PSItem -ErrorAction Stop
	
	}
}



$appnodeConfigFile="$env:BWCE_HOME\tibco.home\bw*\*\config\appnode_config.ini"
$POLICY_ENABLED="false"
Check-JAVAHOME
Check-JMXConfig
Check-JavaGCConfig

try {

	if ( -not (Test-Path -Path "$env:BWCE_HOME\tibco.home" -PathType Container) ) {
	
		Expand-Archive -Path c:\resources\bwce-runtime\bwce*.zip -DestinationPath  $env:BWCE_HOME -Force
		Remove-Item  c:\resources\bwce-runtime\bwce*.zip -Force 2> $null
		
		Copy-Item $(Get-ChildItem "$env:BWCE_HOME/tibco.home/bw*/*/bin/bwappnode.tra") "$(Get-ChildItem "$env:BWCE_HOME/tibco.home/bw*/*/bin/bwappnode.tra").bak"
        #TODO: In files bwappnode.tra and bwcommon.tra, path has been hard-coded(specifically APPDIR, see if that can be made dynamic
		(Get-Content "$env:BWCE_HOME/tibco.home/bw*/*/bin/bwappnode.tra" | ForEach-Object {$_ -ireplace "_APPDIR_", "$env:APPDIR"}) -join "`n" | Set-Content -NoNewline -Force "$env:BWCE_HOME/tibco.home/bw*/*/bin/bwappnode.tra"

        New-Item -ItemType file key.properties | Out-Null
		New-Item -ItemType directory $env:BWCE_HOME\tmp | Out-Null
		
		$addonFolder = "c:\resources\addons"
		
		if ( Test-Path $addonFolder -PathType Container ) {
		
			#Check-Plugins
			#Check-Agents
			#Check-Libs
			#Check-ThirdPartyInstallations
		
			#TODO: had a bug where hidden files were added to jars folder and this condition let to an error....need to modify this instruction
			$jarFolder = "c:\resources\addons\jars"
			
			print-Debug("Copying Addons Jars if present")
			
			if ( (Test-Path $jarFolder) -and (get-item $jarFolder).GetFileSystemInfos().Count -gt 0 ) {
				Copy-Item "c:\resources\addons\jars\*" -Destination $(Get-ChildItem -Path "$env:BWCE_HOME\tibco.home\bw*\*\system\hotfix\shared\") -Recurse
				Write-Output "Copied Addons Jars"
			}
		
		}
		
		New-Item -ItemType SymbolicLink -Path $(Get-ChildItem -Path "$env:BWCE_HOME\tibco.home\bw*\*\bin\") -Name bwapp.ear -Target C:\*.ear | Out-Null
		
		<# Get-ChildItem $env:BWCE_HOME\tibco.home\bwce\2.4\config |
			ForEach-Object {
			
				write-output $_.Name
		
			}  #>
		
		Copy-Item $(Get-ChildItem $appnodeConfigFile) "$(Get-ChildItem $appnodeConfigFile).bak" 
       
		<#Get-ChildItem $env:BWCE_HOME\tibco.home\bwce\2.4\config |
			ForEach-Object {
			
				write-output $_.Name
		
			}  #>
	   
	   
	   
	   
		(Get-Content $appnodeConfigFile | ForEach-Object {$_ -ireplace "_APPDIR_", "$env:BWCE_HOME"}) -join "`n" | Set-Content -NoNewline -Force $appnodeConfigFile
		
		#Rename-Item -Path "C:\tmp\tibco.home\bwce\2.4\bin\bwapp.ear" -NewName bwapp.zip | Out-Null
		Rename-Item $(Get-ChildItem "C:\tmp\tibco.home\bw*\*\bin\bwapp.ear") -NewName bwapp.zip | Out-Null
		
		#Expand-Archive -Path $env:BWCE_HOME\tibco.home\bw*\*\bin\bwapp.ear -DestinationPath C:\tmp -Force
		Expand-Archive -Path $env:BWCE_HOME\tibco.home\bw*\*\bin\bwapp.zip -DestinationPath C:\tmp -Force | Out-Null
		
		#Rename-Item -Path "C:\tmp\tibco.home\bwce\2.4\bin\bwapp.zip" -NewName bwapp.ear | Out-Null
		Rename-Item $(Get-ChildItem "C:\tmp\tibco.home\bw*\*\bin\bwapp.zip") -NewName bwapp.ear | Out-Null
		
		Set-LogLevel
		#memoryCalculator()
		#Check-EnvSubstituteConfig	
		
	}	
	
	Check-Profile
	Check-Policy
	#setupThirdPartyInstallationEnvironment
	
	if ( [System.IO.File]::Exists($(Get-ChildItem -Path "C:\*.substvar")) ) {
	
		Copy-Item $(Get-ChildItem -Path "C:\*.substvar") -Destination $env:BWCE_HOME\tmp\pcf.substvar
		
	} else {
		
		Copy-Item $env:BWCE_HOME\META-INF\$env:BW_PROFILE -Destination $env:BWCE_HOME\tmp\pcf.substvar
	}
	
    # write-output $env:bwBundleAppName
	. $env:JAVA_HOME\bin\java -cp "$(Get-ChildItem "c:\tmp\tibco.home\bw*\*\system\shared\com.tibco.bwce.profile.resolver_*.jar");$(Get-ChildItem "c:\tmp\tibco.home\bw*\*\system\shared\com.tibco.tpcl.com.fasterxml.jackson_*\*");$(Get-ChildItem "c:\tmp\tibco.home\bw*\*\system\shared\com.tibco.bw.tpcl.org.codehaus.jettison_*\*");$env:BWCE_HOME;$env:JAVA_HOME\lib" -DBWCE_APP_NAME="$env:bwBundleAppName" com.tibco.bwce.profile.resolver.Resolver
	
	
} catch {
	#$pscmdlet.ThrowTerminatingError($_)
	#Write-Error -Exception $PSItem -ErrorAction Stop
	#throw
	Write-Output $PSItem -ErrorAction Stop
    throw

}



