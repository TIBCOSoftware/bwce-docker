# need to figure out that in some functions we're using undefined variables
#...are these variables env variables, if yes
#then need to check then with env part

$BW_LOGLEVEL="debug"
function print_Debug( $message ) {

	try {
	
		if ( -not [String]::IsNullOrEmpty($BW_LOGLEVEL) -and $BW_LOGLEVEL.toLower() -eq "debug" ) {
	
			write-host $message
		
		}
	
	} catch {
	
		Write-Error -Exception $PSItem -ErrorAction Stop
	
	}

}

function checkProfile {

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
			#need to check if we have to handle any special cases
			$bwBundleAppName = select-string $bwAppNameHeader $manifest | %{$_.Line.Split(":")[1]}
			echo $bwBundleAppName
			if ( $env:DISABLE_BWCE_EAR_VALIDATION -ne "True" ) {
			
				$bwEditionHeaderStr = select-string $bwEdition $manifest 
				
				if ($bwEditionHeaderStr) {
				
					write-host " "
				
				} else {
				
					write-host "ERROR: Application $bwBundleAppName is not supported in TIBCO BusinessWorks Container Edition. Convert this application to TIBCO BusinessWorks Container Edition using TIBCO Business Studio Container Edition. Refer Conversion Guide for more details."
					
				}
			
			} else {
			
				write-host "BWCE EAR validation disabled"
			    #TODO: Error Handling
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
					
						write-host "ERROR: Application $bwBundleAppName is using unsupported RV palette and can not be deployed in Docker. Rebuild your application for Docker using TIBCO Business Studio Container Edition."
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
				
		if ( [String]::IsNullOrEmpty(($BW_PROFILE = $defaultProfile)) ) {
    
			write-host "BW_PROFILE is unset. Set it to $defaultProfile"
		
		} else {
		
			switch -Wildcard ( $BW_PROFILE ) {
			
			 	'*substvar' {}
				default 
				{
					$env:BW_PROFILE = "$BW_PROFILE.substvar"
					
				}
			
			}
		
			write-host "BW_PROFILE is set to '$BW_PROFILE'"
		}
		
		
	} catch {
	
		Write-Error -Exception $PSItem -ErrorAction Stop
		exit 1
	
	}
	

}

<#function checkPolicy
{
	try {
	
		if ( $POLICY_ENABLED.toLower() -eq "true" ) {
	
			if ( [System.IO.File]::Exists($appnodeConfigFile) ) {
			
				add-content -path $appnodeConfigFile -value "`r`nbw.governance.enabled=true"
				print_Debug("Set bw.governance.enabled=true")
				
			}
		
		}
	
	} catch {
	
		print_Debug("Error Setting bw.governance property to true. Check if AppNode Config file exists or not.")
		Write-Error -Exception $PSItem -ErrorAction Stop
		exit 1
	}
	
}#>

function setLogLevel
{
	try {
	
		Write-Output "Inside check loglevel function"
	
		####Compile-Error-Came-Here-So-We-Put-Path-In_Quotes
		$logback="$env:BWCE_HOME/tibco.home/bw*/*/config/logback.xml"
	
		if ( -not [String]::IsNullOrEmpty($BW_LOGLEVEL) -and $BW_LOGLEVEL.toLower() -eq "debug" ) {
		
			if ( [System.IO.File]::Exists($logback) ) {
			
				copy $logback $logback.bak
				(Get-Content $logback | ForEach-Object {$_ -ireplace "<root level\s*=.*", "<root level = `"$BW_LOGLEVEL`">"}) -join "`n" | Set-Content -NoNewline -Force $logback
				print_Debug "The loglevel is set to $BW_LOGLEVEL level"
			
			}
		
		} else {
		
			(Get-Content $logback | ForEach-Object {$_ -ireplace "<root level\s*=.*", "<root level = `"ERROR`">"}) -join "`n" | Set-Content -NoNewline -Force $logback
		
		}
	
	} catch {
	
		print_Debug("Error setting log level in logback file")
		Write-Error -Exception $PSItem -ErrorAction Stop
		exit 1
	
	}
}

function checkEnvSubstituteConfig {
    
	try{
	
	Write-Output "Inside checkEnvSubstituteConfig function"
        
		####Compile-Error-Came-Here-So-We-Put-Path-In_Quotes, also need to check if such paths have wildcards or not, hence, maybe we need to enclose them within quotes
		$bwappnodeTRA = "$env:BWCE_HOME\tibco.home\bw*\*\bin\bwappnode.tra"
        #$appnodeConfigFile=$BWCE_HOME\tibco.home\bw*\*\config\appnode_config.ini
        $manifest=c:\tmp\META-INF\MANIFEST.MF
        $bwAppNameHeader="Bundle-SymbolicName"
        $bwBundleAppName = select-string $bwAppNameHeader $manifest | %{$_.Line.Split(":")[1]}
        Set BWCE_APP_NAME=$bwBundleAppName      #check if this is right
        
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
                write-host "---------------------------------------"
                cat $appnodeConfigFile
                write-host "---------------------------------------"
			}
        }
		
    } catch {
	
        print_Debug "Error in setting environment configurations"
		Write-Error -Exception $PSItem -ErrorAction Stop
		
    }
	
}



<#function checkPlugins {

	try {
	
		#make all paths like this dynamic
		$pluginFolder = "c:\resources\addons\plugins"
		
		if ( (Test-Path $pluginFolder) -and (get-item $pluginFolder).GetFileSystemInfos().Count -gt 0 ) {
		
			print_Debug("Adding Plug-in Jars")
			#check this condition 
			$addonsFilePath = "$BWCE_HOME\tibco.home\bw*\*\ext\shared"
			#Added quotes in pathe here, don't know why and not sure if addons link will be evaluated to absolute path or not
			"name=Addons Factory`r`ntype=bw6`r`nlayout=bw6ext`r`nlocation=$env:BWCE_HOME\tibco.home\addons" > Get-ChildItem "$addonsFilePath"+"\addons.link"
			
			
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
	
		Write-Error -Exception $PSItem -ErrorAction Stop
	
	}


}#>


function checkJAVAHOME {

	try {
	
		Write-Output "Inside checkJAVAHOME function"
	
		if ( -not [String]::IsNullOrEmpty($JAVA_HOME) ) {
		#if ( $JAVA_HOME ) {
		
			print_Debug($JAVA_HOME)
			
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

function checkJavaGCConfig {
	
	try {
	
		Write-Output "Inside checkJavaGCConfig function"
	
		if ( -not [String]::IsNullOrEmpty($BW_JAVA_GC_OPTS) ) {
	
			 print_Debug($BW_JAVA_GC_OPTS)
			 
		} else {
		
			SET BW_JAVA_GC_OPTS="-XX:+UseG1GC"
			
		}
	
	} catch {
	
		Write-Error -Exception $PSItem -ErrorAction Stop
	
	}

}

function checkJMXConfig
{
	try {
	
		Write-Output "Inside checkJMXConfig function"
	
		if ( -not [String]::IsNullOrEmpty($BW_JMX_CONFIG) ) {
		
			if ( $BW_JMX_CONFIG -like '*:*' ) {
			
				$JMX_HOST=$BW_JMX_CONFIG.Split(":")[0]
				$JMX_PORT=$BW_JMX_CONFIG.Split(":")[1]
			
			} else {
			
				$JMX_HOST="127.0.0.1"
				$JMX_PORT=$BW_JMX_CONFIG
			
			}
			
			$JMX_PARAM="-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=""$JMX_PORT"" -Dcom.sun.management.jmxremote.rmi.port=""$JMX_PORT"" -Djava.rmi.server.hostname=""$JMX_HOST"" -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.local.only=false "
			SET BW_JAVA_OPTS=$BW_JAVA_OPTS" "$JMX_PARAM
		
		}
	
	} catch {
	
		Write-Error -Exception $PSItem -ErrorAction Stop
	
	}
}



$appnodeConfigFile="$env:BWCE_HOME\tibco.home\bw*\*\config\appnode_config.ini"
$POLICY_ENABLED="false"
checkJAVAHOME
checkJMXConfig
checkJavaGCConfig

try {

	if ( -not (Test-Path -Path "$env:BWCE_HOME\tibco.home" -PathType Container) ) {
	
		Expand-Archive -Path c:\resources\bwce-runtime\bwce*.zip -DestinationPath  $env:BWCE_HOME -Force
		Remove-Item  c:\resources\bwce-runtime\bwce*.zip -Force 2> $null
		
		<#Get-ChildItem $env:BWCE_HOME\tibco.home\bwce\2.3\bin |
			ForEach-Object {
			
				write-output $_.Name
		
			}#>
		
		
		#check condition below to ensure APPDIR is getting replaced properly and no inconsistencies are being introduced
		(Get-Content "$env:BWCE_HOME/tibco.home/bw*/*/bin/bwappnode.tra" | ForEach-Object {$_ -ireplace "_APPDIR_", "$env:BW_LOGLEVEL"}) -join "`n" | Set-Content -NoNewline -Force "$env:BWCE_HOME/tibco.home/bw*/*/bin/bwappnode.tra"
		New-Item -ItemType file key.properties | Out-Null
		New-Item -ItemType directory $env:BWCE_HOME\tmp | Out-Null
		
		#if ( Test-Path $env:BWCE_HOME\tmp -PathType Container ) { write-host "partial-ex" } else {write-host "nahi-chali" }
		
		$addonFolder = "c:\resources\addons"
		cd 
		if ( Test-Path $addonFolder -PathType Container ) {
		
			#checkPlugins
			#checkAgents
			#checkLibs
			#checkThirdPartyInstallations
		
			#had a bug where hidden files were added to jars folder and this condition let to an error....need to modify this instruction
			$jarFolder = "c:\resources\addons\jars"
			
			if ( (Test-Path $jarFolder) -and (get-item $jarFolder).GetFileSystemInfos().Count -gt 0 ) {
			
				Copy-Item "c:\resources\addons\jars" -Destination $(Get-ChildItem -Path "$env:BWCE_HOME\tibco.home\bw*\*\system\hotfix\shared") -Recurse
			
			}
		
		}
		
		New-Item -ItemType SymbolicLink -Path $(Get-ChildItem -Path "$env:BWCE_HOME\tibco.home\bw*\*\bin\") -Name bwapp.ear -Target C:\*.ear
		#bakslah confusion as config has forward slashes
		
		Get-ChildItem $env:BWCE_HOME\tibco.home\bwce\2.3\bin |
			ForEach-Object {
			
				write-output $_.Name
		
			} 
		
		(Get-Content $appnodeConfigFile | ForEach-Object {$_ -ireplace "_APPDIR_", "$env:BWCE_HOME"}) -join "`n" | Set-Content -NoNewline -Force $appnodeConfigFile
		#hack-hardcoded-need-better
		Rename-Item -Path "C:\tmp\tibco.home\bwce\2.3\bin\bwapp.ear" -NewName bwapp.zip 
		
		#Expand-Archive -Path $env:BWCE_HOME\tibco.home\bw*\*\bin\bwapp.ear -DestinationPath C:\tmp -Force
		Expand-Archive -Path $env:BWCE_HOME\tibco.home\bw*\*\bin\bwapp.zip -DestinationPath C:\tmp -Force
		Rename-Item -Path "C:\tmp\tibco.home\bwce\2.3\bin\bwapp.zip" -NewName bwapp.ear
		setLogLevel
		#memoryCalculator()
		#checkEnvSubstituteConfig()	
		<# write-output "***META-INF-TEST******"
		Get-ChildItem $env:BWCE_HOME\META-INF |
			ForEach-Object {
			
				write-output $_.Name
		
			}
		write-output "***META-INF-TEST******" #>
	}	
	
	checkProfile
	#checkPolicy
	#setupThirdPartyInstallationEnvironment
	
	if ( [System.IO.File]::Exists($(Get-ChildItem -Path "C:\*.substvar")) ) {
	
		Copy-Item $(Get-ChildItem -Path "C:\*.substvar") -Destination $env:BWCE_HOME\tmp\pcf.substvar
		
	} else {
		#hardcoded profile file name, need to change...env variable setting problem
		Copy-Item $env:BWCE_HOME\META-INF\default.substvar -Destination $env:BWCE_HOME\tmp\pcf.substvar
		
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
	
	<#write-host "temp-check"
	Get-ChildItem \tmp\tmp\ |
			ForEach-Object {
			
				write-output $_.Name
		
			} 
	write-host "temp-check-end"
	write-host [Environment]::UserName
	Get-LocalUser -Name "Administrator" #>
	
	#apply ICACLS rule 
	#ICACLS \tmp\tmp /GRANT everyone:F
	#ICACLS \tmp\tmp /grant:r ContainerAdministrator:F /t
	#ICACLS \tmp\tmp /GRANT *S-1-1-0:F /T
	
	#write-output $env:username
	#Get-Content $env:BWCE_HOME\pcf.substvar
	. $env:JAVA_HOME\bin\java -cp "c:\tmp\tibco.home\bwce\2.3\system\shared\com.tibco.bwce.profile.resolver_1.0.1.002.jar;c:\tmp\tibco.home\bwce\2.3\system\shared\com.tibco.tpcl.com.fasterxml.jackson_2.1.4.001\*;c:\tmp\tibco.home\bwce\2.3\system\shared\com.tibco.bw.tpcl.org.codehaus.jettison_1.4.0.001\*;$env:BWCE_HOME;$env:JAVA_HOME\lib" com.tibco.bwce.profile.resolver.Resolver
	#. $env:JAVA_HOME\bin\java -cp "c:\tmp\tibco.home\bwce\2.3\system\shared\com.tibco.bwce.profile.resolver_1.0.1.002.jar;c:\tmp\tibco.home\bwce\2.3\system\shared\com.tibco.tpcl.com.fasterxml.jackson_2.1.4.001\*;c:\tmp\tibco.home\bwce\2.3\system\shared\com.tibco.bw.tpcl.org.codehaus.jettison_1.4.0.001\*;$env:BWCE_HOME;$env:JAVA_HOME\lib" "-DBWCE_APP_NAME=$bwBundleAppName" com.tibco.bwce.profile.resolver.Resolver -Verb runAs Administrator
	
	#-> working. "$env:JAVA_HOME\bin\java -cp c:\tmp\tibco.home\bwce\2.3\system\shared\com.tibco.bwce.profile.resolver_1.0.1.002.jar;c:\tmp\tibco.home\bwce\2.3\system\shared\com.tibco.tpcl.com.fasterxml.jackson_2.1.4.001\*;c:\tmp\tibco.home\bwce\2.3\system\shared\com.tibco.bw.tpcl.org.codehaus.jettison_1.4.0.001\*;$env:BWCE_HOME;$env:JAVA_HOME\lib" "-DBWCE_APP_NAME=$bwBundleAppName" com.tibco.bwce.profile.resolver.Resolver
	
	#Invoke-Process -FilePath "$env:JAVA_HOME\bin\java" -ArugmentList "-version" -NoNewWindow
	#Start-Process -FilePath "$env:JAVA_HOME\bin\java" -ArgumentList "-cp c:\tmp\tibco.home\bwce\2.3\system\shared\com.tibco.bwce.profile.resolver_1.0.1.002.jar;c:\tmp\tibco.home\bwce\2.3\system\shared\com.tibco.tpcl.com.fasterxml.jackson_2.1.4.001\*;c:\tmp\tibco.home\bwce\2.3\system\shared\com.tibco.bw.tpcl.org.codehaus.jettison_1.4.0.001\*;$env:BWCE_HOME;$env:JAVA_HOME\lib" "-DBWCE_APP_NAME=$bwBundleAppName" com.tibco.bwce.profile.resolver.Resolver -NoNewWindow
	
	<# $STATUS=$?

	if ( $STATUS ) {

		echo "********Error - Nitish Log************"
		exit 1 # terminate and indicate error

	} #>
	write-host "c:\tmp\tibco.home\bwce\2.3\system\hotfix\shared\********************"
	Get-ChildItem c:\tmp\tibco.home\bwce\2.3\system\hotfix\shared\jars\ |
			ForEach-Object {
			
				write-output $_.Name
		
			} 
	write-host "**********c:\tmp\tibco.home\bwce\2.3\system\hotfix\shared\*************ENNDDDDD"
	
	
} catch {
	#$pscmdlet.ThrowTerminatingError($_)
	#Write-Error -Exception $PSItem -ErrorAction Stop
	#throw
	Write-Output $PSItem -ErrorAction Stop
    throw

}



