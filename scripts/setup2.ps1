# need to figure out that in some functions we're using undefined variables
#...are these variables env variables, if yes
#then need to check then with env part

#$BW_LOGLEVEL="debug"
$ProgressPreference = 'SilentlyContinue'
function print_Debug() {
	
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


function Get-ErrorInformation {
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

}



function Check-Profile {

   [cmdletbinding()]
   param() 

	try {
	
		Write-Output "Inside CheckProfile function"

		$BUILD_DIR=$env:BWCE_HOME
		$defaultProfile="default.substvar"
		$manifest=$BUILD_DIR+"\META-INF\MANIFEST.MF"
		$bwAppConfig="TIBCO-BW-ConfigProfile"
		$bwAppNameHeader="Bundle-SymbolicName"
		$bwEdition="bwcf"
		#bwceTarget='TIBCO-BWCE-Edition-Target:'
		if ( [System.IO.File]::Exists($manifest) ) { 
			
			$bwAppProfileStr = select-string $bwAppConfig+".*.substvar" $manifest | ForEach-Object Line
			echo $bwAppProfileStr
            $env:bwBundleAppName = select-string $bwAppNameHeader $manifest | %{$_.Line.Split(":")[1].Trim()}
			echo $env:bwBundleAppName
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
				echo $name
				$fileExtension = $_.Extension
                
				if ( $fileExtension -eq ".jar" ) {
				
					New-Item -Path $BUILD_DIR\temp
					#Check how to do quiet unzipping
					Expand-Archive -Path $BUILD_DIR\tibco.home\$name -DestinationPath $BUILD_DIR\temp -Force
					####Compile-Error-Came-Here-So-We-Put-Path-In_Quotes
					$MANIFESTMF= "$BUILD_DIR\temp\META-INF\MANIFEST.MF"
					#need to check if we have to handle any special cases here as well(shell script had a long command)
					$bwcePaletteStr = select-string  -Quiet 'bw.rv' $MANIFESTMF 
					
					$bwcePolicyPatternArray = "bw.authxml", "bw.cred" , "bw.ldap", "bw.wss", "bw.dbauth", "bw.kerberos", "bw.realmdb", "bw.ldaprealm", "bw.userid"
					$bwcePolicyStr = select-string  -Quiet $bwcePolicyPatternArray $MANIFESTMF
					
					#check if this condition works properly
					Remove-Item $BUILD_DIR\temp -Force -Recurse
					
					if ( $bwcePaletteStr ) {
					
						Write-Error "ERROR: Application $bwBundleAppName is using unsupported RV palette and can not be deployed in Docker. Rebuild your application for Docker using TIBCO Business Studio Container Edition."
						Exit 1
					}
					
					if ( $bwcePolicyStr ) {
						#check this boolean assignment as well, and set it globally
						$POLICY_ENABLED = $true
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

            Write-Output "Iside Policy enabled true condition"
	
			if ( Test-Path -Path $appnodeConfigFile -PathType leaf ) {
			
				Add-Content -Path $appnodeConfigFile -Value "`r`nbw.governance.enabled=true"
				print_Debug("Set bw.governance.enabled=true")
		
			}
		
		}
	
	} catch {
	
		print_Debug("Error Setting bw.governance property to true. Check if AppNode Config file exists or not.")
		Write-Error -Exception $PSItem -ErrorAction Stop

	}
	
}

function Set-LogLevel {
    
    [CmdletBinding()]
	param()
	
    try {
	
		Write-Output "Inside setloglevel function"
	
		####Compile-Error-Came-Here-So-We-Put-Path-In_Quotes
		$logback="$env:BWCE_HOME\tibco.home\bw*\*\config\logback.xml"
		#need to correct this -> should be taken from an env variable
		write-output "***Log Level Check****"
		write-output $env:BW_LOGLEVEL

		if ( -not [String]::IsNullOrEmpty($env:BW_LOGLEVEL) -and $env:BW_LOGLEVEL.toLower() -eq "debug" ) {
		   
			if ( Test-Path -Path $logback -PathType leaf) {
			   
				Copy-Item -Path $logback -Destination $logback.bak
				(Get-Content $logback | ForEach-Object {$_ -ireplace "<root level\s*=.*", "<root level = `"$env:BW_LOGLEVEL`">"}) -join "`n" | Set-Content -NoNewline -Force $logback
				print_Debug "The loglevel is set to $env:BW_LOGLEVEL level"
			
			}
		
		} else {
           
			Write-Output "Setting loglevel to Error"
			(Get-Content $logback | ForEach-Object {$_ -ireplace "<root level\s*=.*", "<root level = `"ERROR`">"}) -join "`n" | Set-Content -NoNewline -Force $logback
		
		}
	
	} catch {
	
		print_Debug("Error setting log level in logback file")
		Write-Error -Exception $PSItem -ErrorAction Stop
	
	}

}

function Check-EnvSubstituteConfig {

    [CmdletBinding()]
	param()
    
	try{
	
	Write-Output "Inside checkEnvSubstituteConfig function"
        
		####Compile-Error-Came-Here-So-We-Put-Path-In_Quotes, also need to check if such paths have wildcards or not, hence, maybe we need to enclose them within quotes
		$bwappnodeTRA = "$env:BWCE_HOME\tibco.home\bw*\*\bin\bwappnode.tra"
        #$appnodeConfigFile=$BWCE_HOME\tibco.home\bw*\*\config\appnode_config.ini
        $manifest=c:\tmp\META-INF\MANIFEST.MF
        $bwAppNameHeader="Bundle-SymbolicName"
        $bwBundleAppName = select-string $bwAppNameHeader $manifest | %{$_.Line.Split(":")[1]}
        $env:BWCE_APP_NAME=$bwBundleAppName      
        
        if([System.IO.File]::Exists($bwappnodeTRA)){
            copy $bwappnodeTRA $bwappnodeTRA.bak
            (Get-Content $bwappnodeTRA | ForEach-Object {$_ -replace "-Djava.class.path=", "-Djava.class.path=$ADDONS_HOME/lib:"}) -join "`n" | Set-Content -NoNewline -Force $bwappnodeTRA
            print_Debug "Appended ADDONS_HOME/lib in bwappnode.tra file"
        }
        #if([System.IO.File]::Exists($bwappnodeFile)){
        #    copy $bwappnodeFile $bwappnodeFile.bak
        #    (Get-Content $bwappnodeTRA | ForEach-Object {$_ -replace "-Djava.class.path=", "-Djava.class.path=$ADDONS_HOME/lib:"}) -join "`n" | Set-Content -NoNewline -Force $bwappnodeTRA
        #    print_Debug "Appended ADDONS_HOME/lib in bwappnode.tra file"
        #} 
        if($BW_JAVA_OPTS){
            if([System.IO.File]::Exists($bwappnodeTRA)){
                #sed -i.bak "/java.extended.properties/s/$/ ${BW_JAVA_OPTS}/" $bwappnodeTRA
                print_Debug "Appended $BW_JAVA_OPTS to java.extend.properties"
            }
        }
        if($BW_ENGINE_THREADCOUNT){
            if([System.IO.File]::Exists($appnodeConfigFile)){
                    add-content -path $appnodeConfigFile -value "`r`nbw.engine.threadCount=$BW_ENGINE_THREADCOUNT"
                    print_Debug "set BW_ENGINE_THREADCOUNT to $BW_ENGINE_THREADCOUNT"
            }
        }
        if($BW_ENGINE_STEPCOUNT){
            if([System.IO.File]::Exists($appnodeConfigFile)){
                    add-content -path $appnodeConfigFile -value "`r`nbw.engine.stepCount=$BW_ENGINE_STEPCOUNT"
                    print_Debug "set BW_ENGINE_STEPCOUNT to $BW_ENGINE_STEPCOUNT"
            }
        }
        if($BW_APPLICATION_JOB_FLOWLIMIT){
            if([System.IO.File]::Exists($BW_APPLICATION_JOB_FLOWLIMIT)){
                    add-content -path $appnodeConfigFile -value "`r`nbw.application.job.flowlimit.$bwBundleAppName=$BW_APPLICATION_JOB_FLOWLIMIT"
                    print_Debug "set BW_APPLICATION_JOB_FLOWLIMIT to $BW_APPLICATION_JOB_FLOWLIMIT"
            }
        }
        if($BW_APP_MONITORING_CONFIG){
            if([System.IO.File]::Exists($appnodeConfigFile)){
                (Get-Content $appnodeConfigFile | ForEach-Object {$_ -replace "bw.frwk.event.subscriber.metrics.enabled=false", "bw.frwk.event.subscriber.metrics.enabled=true"}) -join "`n" | Set-Content -NoNewline -Force $appnodeConfigFile
                print_Debug "set bw.frwk.event.subscriber.metrics.enabled to true"
            }
        }
        if($BW_LOGLEVEL -eq "DEBUG"){
            if($BW_APPLICATION_JOB_FLOWLIMIT -or $BW_ENGINE_STEPCOUNT -or $BW_ENGINE_THREADCOUNT -or $BW_APP_MONITORING_CONFIG){
                Write-Output "---------------------------------------"
                cat $appnodeConfigFile
                Write-Output "---------------------------------------"
			}
        }
		
    } catch {
	
        print_Debug "Error in setting environment configurations"
		Write-Error -Exception $PSItem -ErrorAction Stop
		
    }
	
}



function Check-Plugins {
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
					New-Item -Path $env:BWCE_HOME\tibco.home\addons\runtime\plugins 
					Move-Item -Path $env:BWCE_HOME\plugintmp\runtime\plugins\* -Destination $env:BWCE_HOME\tibco.home\addons\runtime\plugins
					New-Item -Path $env:BWCE_HOME\tibco.home\addons\bin
					#need to check this line for null condition
					Move-Item -Path $env:BWCE_HOME\plugintmp\bin\* -Destination $env:BWCE_HOME\tibco.home\addons\bin 2> $null
				
				}
			
			}
	
		} catch {
		
			#Write-Error -Exception $PSItem -ErrorAction Stop
			Get-ErrorInformation -incomingError $_ -ErrorAction Stop
		
		}
	
	}


}


function Check-JAVAHOME {

    [CmdletBinding()]
	param()

	try {
	
		Write-Output "Inside checkJAVAHOME function"
	
		if ( -not [String]::IsNullOrEmpty($env:JAVA_HOME) ) {
		#if ( $JAVA_HOME ) {
		
			print_Debug($env:JAVA_HOME)
			
		} else {
			print_Debug("set java home")
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
	
		Write-Output "Inside checkJavaGCConfig function"
	
		if ( -not [String]::IsNullOrEmpty($env:BW_JAVA_GC_OPTS) ) {
	
			 print_Debug($env:BW_JAVA_GC_OPTS)
			 
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
	
		Write-Output "Inside checkJMXConfig function"
	
		if ( -not [String]::IsNullOrEmpty($env:BW_JMX_CONFIG) ) {
		
			if ( $env:BW_JMX_CONFIG -like '*:*' ) {
			
				$JMX_HOST=$env:BW_JMX_CONFIG.Split(":")[0]
				$JMX_PORT=$env:BW_JMX_CONFIG.Split(":")[1]
			
			} else {
			
				$JMX_HOST="127.0.0.1"
				$JMX_PORT=$env:BW_JMX_CONFIG
			
			}
			
			$JMX_PARAM="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=""$JMX_PORT"" -Dcom.sun.management.jmxremote.rmi.port=""$JMX_PORT"" -Djava.rmi.server.hostname=""$JMX_HOST"" -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.local.only=false "
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
		
		<#Get-ChildItem $env:BWCE_HOME\tibco.home\bwce\2.3\bin |
			ForEach-Object {
			
				write-output $_.Name
		
			}#>
		
        #TODO: In files bwappnode.tra and bwcommon.tra, path has been hard-coded(specifically APPDIR, see if that can be made dynamic
		
		#check condition below to ensure APPDIR is getting replaced properly and no inconsistencies are being introduced
		(Get-Content "$env:BWCE_HOME/tibco.home/bw*/*/bin/bwappnode.tra" | ForEach-Object {$_ -ireplace "_APPDIR_", "$env:BW_LOGLEVEL"}) -join "`n" | Set-Content -NoNewline -Force "$env:BWCE_HOME/tibco.home/bw*/*/bin/bwappnode.tra"
		####++++++++++++###########


        New-Item -ItemType file key.properties | Out-Null
		New-Item -ItemType directory $env:BWCE_HOME\tmp | Out-Null
		
		#if ( Test-Path $env:BWCE_HOME\tmp -PathType Container ) { Write-Output "partial-ex" } else {Write-Output "nahi-chali" }
		
		$addonFolder = "c:\resources\addons"
		
		if ( Test-Path $addonFolder -PathType Container ) {
		
			#Check-Plugins
			#Check-Agents
			#Check-Libs
			#Check-ThirdPartyInstallations
		
			#had a bug where hidden files were added to jars folder and this condition let to an error....need to modify this instruction
			$jarFolder = "c:\resources\addons\jars"
			
			if ( (Test-Path $jarFolder) -and (get-item $jarFolder).GetFileSystemInfos().Count -gt 0 ) {
			
				Copy-Item "c:\resources\addons\jars" -Destination $(Get-ChildItem -Path "$env:BWCE_HOME\tibco.home\bw*\*\system\hotfix\shared") -Recurse
			
			}
		
		}
		
		New-Item -ItemType SymbolicLink -Path $(Get-ChildItem -Path "$env:BWCE_HOME\tibco.home\bw*\*\bin\") -Name bwapp.ear -Target C:\*.ear
		#bakslah confusion as config has forward slashes
		
		<#Get-ChildItem $env:BWCE_HOME\tibco.home\bwce\2.3\bin |
			ForEach-Object {
			
				write-output $_.Name
		
			} #>
		
		(Get-Content $appnodeConfigFile | ForEach-Object {$_ -ireplace "_APPDIR_", "$env:BWCE_HOME"}) -join "`n" | Set-Content -NoNewline -Force $appnodeConfigFile
		#hack-hardcoded-need-better
		Rename-Item -Path "C:\tmp\tibco.home\bwce\2.3\bin\bwapp.ear" -NewName bwapp.zip | Out-Null
		
		#Expand-Archive -Path $env:BWCE_HOME\tibco.home\bw*\*\bin\bwapp.ear -DestinationPath C:\tmp -Force
		Expand-Archive -Path $env:BWCE_HOME\tibco.home\bw*\*\bin\bwapp.zip -DestinationPath C:\tmp -Force | Out-Null
		Rename-Item -Path "C:\tmp\tibco.home\bwce\2.3\bin\bwapp.zip" -NewName bwapp.ear | Out-Null
		Set-LogLevel
		#memoryCalculator()
		#checkEnvSubstituteConfig()	
		<# write-output "***META-INF-TEST******"
		Get-ChildItem $env:BWCE_HOME\META-INF |
			ForEach-Object {
			
				write-output $_.Name
		
			}
		write-output "***META-INF-TEST******" #>
	}	
	
	Check-Profile
	Check-Policy
	#setupThirdPartyInstallationEnvironment
	
	if ( [System.IO.File]::Exists($(Get-ChildItem -Path "C:\*.substvar")) ) {
	
		Copy-Item $(Get-ChildItem -Path "C:\*.substvar") -Destination $env:BWCE_HOME\tmp\pcf.substvar
		
	} else {
		#hardcoded profile file name, need to change...env variable setting problem
		Copy-Item $env:BWCE_HOME\META-INF\$env:BW_PROFILE -Destination $env:BWCE_HOME\tmp\pcf.substvar
		
		<# write-output "****profile env variable*******"
		write-output $env:BW_PROFILE
		write-output "****profile env variable end*******"
		write-output "*****File-COntent*******"
		Get-Content "$env:BWCE_HOME\META-INF\default.substvar"
		write-output "*****File-COntent*******"
		
		
		Get-ChildItem $env:BWCE_HOME\META-INF\$env:BW_PROFILE |
			ForEach-Object {
			
				write-output $_.Name
		
			}
		
	 #>
	}
	
	<#Write-Output "temp-check"
	Get-ChildItem \tmp\tmp\ |
			ForEach-Object {
			
				write-output $_.Name
		
			} 
	Write-Output "temp-check-end"
	Write-Output [Environment]::UserName
	Get-LocalUser -Name "Administrator" #>
	
	#apply ICACLS rule 
	#ICACLS \tmp\tmp /GRANT everyone:F
	#ICACLS \tmp\tmp /grant:r ContainerAdministrator:F /t
	#ICACLS \tmp\tmp /GRANT *S-1-1-0:F /T
	
	#write-output $env:username
	#Get-Content $env:BWCE_HOME\pcf.substvar
    write-output $env:bwBundleAppName
	. $env:JAVA_HOME\bin\java -cp "c:\tmp\tibco.home\bwce\2.3\system\shared\com.tibco.bwce.profile.resolver_1.0.1.002.jar;c:\tmp\tibco.home\bwce\2.3\system\shared\com.tibco.tpcl.com.fasterxml.jackson_2.1.4.001\*;c:\tmp\tibco.home\bwce\2.3\system\shared\com.tibco.bw.tpcl.org.codehaus.jettison_1.4.0.001\*;$env:BWCE_HOME;$env:JAVA_HOME\lib" -DBWCE_APP_NAME="$env:bwBundleAppName" com.tibco.bwce.profile.resolver.Resolver
	#. $env:JAVA_HOME\bin\java -cp "c:\tmp\tibco.home\bwce\2.3\system\shared\com.tibco.bwce.profile.resolver_1.0.1.002.jar;c:\tmp\tibco.home\bwce\2.3\system\shared\com.tibco.tpcl.com.fasterxml.jackson_2.1.4.001\*;c:\tmp\tibco.home\bwce\2.3\system\shared\com.tibco.bw.tpcl.org.codehaus.jettison_1.4.0.001\*;$env:BWCE_HOME;$env:JAVA_HOME\lib" "-DBWCE_APP_NAME=$bwBundleAppName" com.tibco.bwce.profile.resolver.Resolver -Verb runAs Administrator
	
	#-> working. "$env:JAVA_HOME\bin\java -cp c:\tmp\tibco.home\bwce\2.3\system\shared\com.tibco.bwce.profile.resolver_1.0.1.002.jar;c:\tmp\tibco.home\bwce\2.3\system\shared\com.tibco.tpcl.com.fasterxml.jackson_2.1.4.001\*;c:\tmp\tibco.home\bwce\2.3\system\shared\com.tibco.bw.tpcl.org.codehaus.jettison_1.4.0.001\*;$env:BWCE_HOME;$env:JAVA_HOME\lib" "-DBWCE_APP_NAME=$bwBundleAppName" com.tibco.bwce.profile.resolver.Resolver
	
	#Invoke-Process -FilePath "$env:JAVA_HOME\bin\java" -ArugmentList "-version" -NoNewWindow
	#Start-Process -FilePath "$env:JAVA_HOME\bin\java" -ArgumentList "-cp c:\tmp\tibco.home\bwce\2.3\system\shared\com.tibco.bwce.profile.resolver_1.0.1.002.jar;c:\tmp\tibco.home\bwce\2.3\system\shared\com.tibco.tpcl.com.fasterxml.jackson_2.1.4.001\*;c:\tmp\tibco.home\bwce\2.3\system\shared\com.tibco.bw.tpcl.org.codehaus.jettison_1.4.0.001\*;$env:BWCE_HOME;$env:JAVA_HOME\lib" "-DBWCE_APP_NAME=$bwBundleAppName" com.tibco.bwce.profile.resolver.Resolver -NoNewWindow
	
	<# $STATUS=$?

	if ( $STATUS ) {

		echo "********Error - Nitish Log************"
		exit 1 # terminate and indicate error

	} #>
	<# Write-Output "c:\tmp\tibco.home\bwce\2.3\system\hotfix\shared\********************"
	Get-ChildItem c:\tmp\tibco.home\bwce\2.3\system\hotfix\shared\jars\ |
			ForEach-Object {
			
				write-output $_.Name
		
			} 
	Write-Output "**********c:\tmp\tibco.home\bwce\2.3\system\hotfix\shared\*************ENNDDDDD" #>
	
} catch {
	#$pscmdlet.ThrowTerminatingError($_)
	#Write-Error -Exception $PSItem -ErrorAction Stop
	#throw
	Write-Output $PSItem -ErrorAction Stop
    throw

}



