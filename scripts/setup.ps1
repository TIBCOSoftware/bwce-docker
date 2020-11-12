$ProgressPreference = 'SilentlyContinue'

function Print-Debug () {

	[CmdletBinding()]
	param($message)

	process {

		try {

			if (-not [string]::IsNullOrEmpty($env:BW_LOGLEVEL) -and $env:BW_LOGLEVEL.ToLower() -eq "debug") {

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

	[CmdletBinding()]
	param()

	try {

		Print-Debug ("Inside CheckProfile function")

		$BUILD_DIR = $env:BWCE_HOME
		$defaultProfile = "default.substvar"
		$manifest = $BUILD_DIR + "\META-INF\MANIFEST.MF"
		$bwAppConfig = "TIBCO-BW-ConfigProfile"
		$bwAppNameHeader = "Bundle-SymbolicName"
		$bwEdition = "bwcf"
		#bwceTarget='TIBCO-BWCE-Edition-Target:'
		if ([System.IO.File]::Exists($manifest)) {

			$bwAppProfileStr = Select-String $bwAppConfig+".*.substvar" $manifest | ForEach-Object Line
			Print-Debug ($env:bwAppProfileStr)
			$env:bwBundleAppName = Select-String $bwAppNameHeader $manifest | ForEach-Object { $_.Line.Split(":")[1].Trim() }
			Print-Debug ($env:bwBundleAppName)

			if ($env:DISABLE_BWCE_EAR_VALIDATION -ne "True") {

				$bwEditionHeaderStr = Select-String $bwEdition $manifest

				if (-not [string]::IsNullOrEmpty($bwEditionHeaderStr)) {

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

				if ($fileExtension -eq ".jar") {

					New-Item -Path $BUILD_DIR\temp
					#Check how to do quiet unzipping
					Expand-Archive -Path $BUILD_DIR\tibco.home\$name -DestinationPath $BUILD_DIR\temp -Force
					$MANIFESTMF = "$BUILD_DIR\temp\META-INF\MANIFEST.MF"
					#need to check if we have to handle any special cases here as well(shell script had a long command)
					$bwcePaletteStr = Select-String -Quiet 'bw.rv' $MANIFESTMF

					$bwcePolicyPatternArray = "bw.authxml","bw.cred","bw.ldap","bw.wss","bw.dbauth","bw.kerberos","bw.realmdb","bw.ldaprealm","bw.userid"
					$bwcePolicyStr = Select-String -Quiet $bwcePolicyPatternArray $MANIFESTMF

					#check if this condition works properly
					Remove-Item $BUILD_DIR\temp -Force -Recurse

					if ($bwcePaletteStr) {

						Write-Output "ERROR: Application $bwBundleAppName is using unsupported RV palette and can not be deployed in Docker. Rebuild your application for Docker using TIBCO Business Studio Container Edition."
						exit 1
					}

					if ($bwcePolicyStr) {
						#check this boolean assignment as well, and set it globally
						$POLICY_ENABLED = "true"
						break

					}

				}



			}

		}

		$bwcePolicyStringArray = $bwAppProfileStr -split "/"

		foreach ($individualString in $bwcePolicyStringArray) {

			$defaultProfile = switch -Wildcard ($individualString) {

				'*substvar' {

					$individualString

				}

			}

		}
		
		if ([string]::IsNullOrEmpty($env:BW_PROFILE)) {
			Write-Output "BW_PROFILE is unset. Setting it to $defaultProfile"
			$env:BW_PROFILE = $defaultProfile

		} else {
			
			switch -Wildcard ($env:BW_PROFILE) {

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

		if ($POLICY_ENABLED.ToLower() -eq "true") {

			Print-Debug ("Executing Check-Policy Function")

			if (Test-Path -Path $appnodeConfigFile -PathType leaf) {

				Add-Content -Path $appnodeConfigFile -Value "`r`nbw.governance.enabled=true"
				Print-Debug ("Set bw.governance.enabled=true")

			}

		}

	} catch {

		Print-Debug ("Error Setting bw.governance property to true. Check if AppNode Config file exists or not.")
		Write-Error -Exception $PSItem -ErrorAction Stop

	}

}

function Set-LogLevel {

	[CmdletBinding()]
	param()

	try {
		Print-Debug ("Inside Set-Loglevel function")
		$logback = "$env:BWCE_HOME\tibco.home\bw*\*\config\logback.xml"
		Print-Debug ($env:BW_LOGLEVEL)

		if (-not [string]::IsNullOrEmpty($env:BW_LOGLEVEL)) {

			if (Test-Path -Path $logback -PathType leaf) {

				Copy-Item $(Get-ChildItem $logback) "$(Get-ChildItem $logback).bak"
				(Get-Content $logback | ForEach-Object { $_ -ireplace "<root level\s*=.*","<root level = `"$env:BW_LOGLEVEL`">" }) -join "`n" | Set-Content -NoNewline -Force $logback
				Write-Output "The loglevel is set to $env:BW_LOGLEVEL level"

			}

		} else {

			Write-Output "The loglevel is set to Error"
			Copy-Item $(Get-ChildItem $logback) "$(Get-ChildItem $logback).bak"
			(Get-Content $logback | ForEach-Object { $_ -ireplace "<root level\s*=.*","<root level = `"ERROR`">" }) -join "`n" | Set-Content -NoNewline -Force $logback

		}

	} catch {

		Print-Debug ("Error setting log level in logback file")
		Write-Error -Exception $PSItem -ErrorAction Stop

	}

}

function Check-EnvSubstituteConfig {

	[CmdletBinding()]
	param()

	try {

		Write-Output "Calling Check-EnvSubstituteConfig function"
		$bwappnodeTRA = "$env:BWCE_HOME\tibco.home\bw*\*\bin\bwappnode.tra"
		$appnodeConfigFile = "$env:BWCE_HOME\tibco.home\bw*\*\config\appnode_config.ini"
		$manifest = "c:\tmp\META-INF\MANIFEST.MF"
		$bwAppNameHeader = "Bundle-SymbolicName"
		$bwBundleAppName = Select-String $bwAppNameHeader $manifest | ForEach-Object { $_.Line.Split(":")[1].Trim() }
		$env:BWCE_APP_NAME = $bwBundleAppName

		#TODO: How is addons_home populated(can't see it in env variables"
		if (Test-Path -Path $bwappnodeTRA -PathType leaf) {
			Copy-Item $(Get-ChildItem $bwappnodeTRA) "$(Get-ChildItem $bwappnodeTRA).bak"
			(Get-Content $bwappnodeTRA | ForEach-Object { $_ -replace "-Djava.class.path=","-Djava.class.path=$env:ADDONS_HOME/lib:" }) -join "`n" | Set-Content -NoNewline -Force $bwappnodeTRA
			Print-Debug ("Appended ADDONS_HOME/lib in bwappnode.tra file")
		}

		#TODO: Is appnode even needed?
		#if(Test-Path -Path $bwappnodeFile -PathType leaf){
		#    Copy-Item -Path $bwappnodeFile -Destination "$bwappnodeFile.bak"
		#    (Get-Content $bwappnodeTRA | ForEach-Object {$_ -replace "-Djava.class.path=", "-Djava.class.path=$ADDONS_HOME/lib:"}) -join "`n" | Set-Content -NoNewline -Force $bwappnodeTRA
		#    print_Debug "Appended ADDONS_HOME/lib in bwappnode.tra file"
		#} 

		if ($env:BW_JAVA_OPTS) {
			if (Test-Path -Path $bwappnodeTRA -PathType leaf) {
				Copy-Item $(Get-ChildItem $bwappnodeTRA) "$(Get-ChildItem $bwappnodeTRA).bak"
				$NewContent = Get-Content -Path $bwappnodeTRA |
				ForEach-Object {

					if ($_ -match 'java.extended.properties=.*') {

						$_ + " $env:BW_JAVA_OPTS"

					} else {

						$_

					}
				}

				# Write content of $NewContent varibale back to file
				$NewContent | Out-File -FilePath $bwappnodeTRA -Encoding Default -Force
				Print-Debug "Appended $env:BW_JAVA_OPTS to java.extend.properties"
			}
		}
		if ($env:BW_ENGINE_THREADCOUNT) {
			if (Test-Path -Path $appnodeConfigFile -PathType leaf) {
				Add-Content -Path $appnodeConfigFile -Value "`r`nbw.engine.threadCount=$env:BW_ENGINE_THREADCOUNT"
				Print-Debug ("set BW_ENGINE_THREADCOUNT to $env:BW_ENGINE_THREADCOUNT")
			}
		}
		if ($env:BW_ENGINE_STEPCOUNT) {
			if (Test-Path -Path $appnodeConfigFile -PathType leaf) {
				Add-Content -Path $appnodeConfigFile -Value "`r`nbw.engine.stepCount=$env:BW_ENGINE_STEPCOUNT"
				Print-Debug ("set BW_ENGINE_STEPCOUNT to $env:BW_ENGINE_STEPCOUNT")
			}
		}
		#TODO: Check the condition below, whether concatenation is happening properly or not
		if ($env:BW_APPLICATION_JOB_FLOWLIMIT) {
			if ((Test-Path -Path $appnodeConfigFile -PathType leaf)) {
				Add-Content -Path $appnodeConfigFile -Value "`r`nbw.application.job.flowlimit.$bwBundleAppName=$env:BW_APPLICATION_JOB_FLOWLIMIT"
				Print-Debug ("set BW_APPLICATION_JOB_FLOWLIMIT to $env:BW_APPLICATION_JOB_FLOWLIMIT")
			}
		}
		if ($env:BW_APP_MONITORING_CONFIG -or ($env:TCI_HYBRID_AGENT_HOST -and $env:TCI_HYBRID_AGENT_PORT)) {
			if ((Test-Path -Path $appnodeConfigFile -PathType leaf)) {
				(Get-Content $appnodeConfigFile | ForEach-Object { $_ -replace "bw.frwk.event.subscriber.metrics.enabled=false","bw.frwk.event.subscriber.metrics.enabled=true" }) -join "`n" | Set-Content -NoNewline -Force $appnodeConfigFile
				Print-Debug ("set bw.frwk.event.subscriber.metrics.enabled to true")
			}
		}
		if ($env:TCI_HYBRID_AGENT_HOST -and $env:TCI_HYBRID_AGENT_PORT) {
			if (Test-Path -Path $appnodeConfigFile -PathType leaf) {
				Add-Content -Path $appnodeConfigFile -Value "`r`nbw.frwk.event.subscriber.instrumentation.enabled=true"
				Print-Debug ("set bw.frwk.event.subscriber.instrumentation.enabled to true")
			}
		}
		#Always do strict checking, in this case if step count is set to 0 & no other variable is set, condition will become false, even though the value is there
		if (-not [string]::IsNullOrEmpty($env:BW_LOGLEVEL) -and $env:BW_LOGLEVEL.ToLower() -eq "debug") {
			if (-not [string]::IsNullOrEmpty($env:BW_APPLICATION_JOB_FLOWLIMIT) -or -not [string]::IsNullOrEmpty($env:BW_ENGINE_STEPCOUNT) -or -not [string]::IsNullOrEmpty($env:BW_ENGINE_THREADCOUNT) -or -not [string]::IsNullOrEmpty($env:BW_APP_MONITORING_CONFIG)) {
				Write-Output "---------------------------------------"
				Get-Content $appnodeConfigFile
				Write-Output "---------------------------------------"
			}
		}

	} catch {

		Print-Debug ("Error in setting environment configurations")
		Write-Error -Exception $PSItem -ErrorAction Stop

	}

}



function Check-Plugins {
	param()
	process {

		try {

			Write-Output "Calling Check-Plugins function"
			$pluginFolder = "c:\resources\addons\plugins"

			if ((Test-Path $pluginFolder) -and (Get-ChildItem $pluginFolder -Exclude .*).Count -gt 0) {

				Print-Debug ("Adding Plug-in Jars")
				$addonsFilePath = "$env:BWCE_HOME\tibco.home\bw*\*\ext\shared"
				"name=Addons Factory`r`ntype=bw6`r`nlayout=bw6ext`r`nlocation=$env:BWCE_HOME\tibco.home\addons" | Set-Content -Path "$(Get-ChildItem "$addonsFilePath")\addons.link"

				Get-ChildItem $pluginFolder -Exclude ".*" |
				ForEach-Object {

					$name = $_.Name
					Expand-Archive -Path "$pluginFolder\$name" -DestinationPath $env:BWCE_HOME\plugintmp -Force

					if (Test-Path $env:BWCE_HOME\plugintmp\runtime\plugins\*) {

						New-Item -ItemType directory $env:BWCE_HOME\tibco.home\addons\runtime\plugins | Out-Null
						Move-Item -Path $env:BWCE_HOME\plugintmp\runtime\plugins\* -Destination $env:BWCE_HOME\tibco.home\addons\runtime\plugins\

					}

					if (Test-Path $env:BWCE_HOME\plugintmp\lib\*.ini) {

						New-Item -ItemType directory $env:BWCE_HOME\tibco.home\addons\lib | Out-Null
						$zipFirstName = $name.Split(".")[0]
						Move-Item -Path $env:BWCE_HOME\plugintmp\lib\*.ini -Destination "$env:BWCE_HOME\tibco.home\addons\lib\$zipFirstName.ini"

					}


					if (Test-Path $env:BWCE_HOME\plugintmp\lib\*.jar) {

						#if (!Test-Path $env:BWCE_HOME\tibco.home\addons\lib) {}
						New-Item -ItemType directory $env:BWCE_HOME\tibco.home\addons\lib -Force | Out-Null
						Move-Item -Path $env:BWCE_HOME\plugintmp\lib\*.jar -Destination $env:BWCE_HOME\tibco.home\addons\lib

					}

					if (Test-Path $env:BWCE_HOME\plugintmp\bin) {

						New-Item -ItemType directory $env:BWCE_HOME\tibco.home\addons\bin | Out-Null
						Move-Item -Path $env:BWCE_HOME\plugintmp\bin -Destination $env:BWCE_HOME\tibco.home\addons\bin | Out-Null

					}


					if (Test-Path $env:BWCE_HOME\plugintmp\*) {

						#$source = "$env:BWCE_HOME\plugintmp\"
						#$dest = "C:\"
						#$exclude = @('bin','runtime','lib')
						#Get-ChildItem $source -Recurse -Exclude $exclude | Copy-Item -Destination { Join-Path $dest $_.FullName.Substring($source.length) }
						#$exclude = @('runtime','bin', 'lib')
						Move-Item $env:BWCE_HOME\plugintmp\* "C:\" | Out-Null

					}

					Remove-Item $env:BWCE_HOME\plugintmp -Force -Recurse | Out-Null

				}

			}

		} catch {

			Write-Error -Exception $PSItem -ErrorAction Stop
			#Get-ErrorInformation -incomingError $_ -ErrorAction Stop

		}

	}


}


function Check-JAVAHOME {

	[CmdletBinding()]
	param()

	try {

		Print-Debug ("Inside checkJAVAHOME function")

		if (-not [string]::IsNullOrEmpty($env:JAVA_HOME)) {

			Print-Debug ($env:JAVA_HOME)

		} else {
			Print-Debug ("set java home")
			$env:JAVA_HOME = $env:BWCE_HOME + "\tibco.home\tibcojre64\1.8.0"

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

		Print-Debug ("Inside checkJavaGCConfig function")

		if (-not [string]::IsNullOrEmpty($env:BW_JAVA_GC_OPTS)) {

			Print-Debug ($env:BW_JAVA_GC_OPTS)

		} else {

			$env:BW_JAVA_GC_OPTS = "-XX:+UseG1GC"

		}

	} catch {

		Write-Error -Exception $PSItem -ErrorAction Stop

	}

}

function Check-JMXConfig {

	[CmdletBinding()]
	param()

	try {

		Print-Debug ("Inside checkJMXConfig function")

		if (-not [string]::IsNullOrEmpty($env:BW_JMX_CONFIG)) {

			if ($env:BW_JMX_CONFIG -like '*:*') {

				$JMX_HOST = $env:BW_JMX_CONFIG.Split(":")[0]
				$JMX_PORT = $env:BW_JMX_CONFIG.Split(":")[1]

			} else {

				$JMX_HOST = "127.0.0.1"
				$JMX_PORT = $env:BW_JMX_CONFIG

			}

			$JMX_PARAM = "-Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=$JMX_PORT -Dcom.sun.management.jmxremote.rmi.port=$JMX_PORT -Djava.rmi.server.hostname=$JMX_HOST -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.local.only=false "
			$env:BW_JAVA_OPTS = "$BW_JAVA_OPTS $JMX_PARAM"

		}

	} catch {

		Write-Error -Exception $PSItem -ErrorAction Stop

	}
}

function Check-Certs {

	[CmdletBinding()]
	param()

	try {

		$certificateFolder = "c:\resources\addons\certs"

		if ((Test-Path $certificateFolder) -and (Get-ChildItem $certificateFolder -Exclude .*).Count -gt 0) {

			$JRE_VERSION = Get-ChildItem $env:BWCE_HOME\tibco.home\tibcojre64\* | ForEach-Object { Write-Output $_.Name }
			$JRE_LOCATION = "$env:BWCE_HOME\tibco.home\tibcojre64\$JRE_VERSION"
			$certsStore = "$JRE_LOCATION\lib\security\cacerts"

			Get-ChildItem $certificateFolder -Exclude ".*" |
			ForEach-Object {
				$name = $_.Name
				$fileExtension = $_.Extension

				if ($fileExtension -ne ".jks") {

					Print-Debug ("Importing $name into java truststore")
					$aliasName = $name.Split(".")[0]
					#.$JRE_LOCATION\bin\keytool.exe -import -trustcacerts -keystore $certsStore -storepass changeit -noprompt -alias $aliasName -file $name
					$certificateFullPath = "$certificateFolder\$name"
					$AllArgs = @('-import','-trustcacerts','-storepass ','changeit','-keystore ',$certsStore,'-alias ',$aliasName,'-file ',$certificateFullPath,'-noprompt')
					. $JRE_LOCATION\bin\keytool.exe $AllArgs
				}

			}

		}


	} catch {

		Write-Error -Exception $PSItem -ErrorAction Stop

	}

}


function Check-Agents {

	[CmdletBinding()]
	param()

	try {

		$agentFolder = "c:\resources\addons\agents"

		if ((Test-Path $agentFolder) -and (Get-ChildItem $agentFolder -Exclude .*).Count -gt 0) {

			Print-Debug ("Adding Monitoring Jars")

			Get-ChildItem $agentFolder -Exclude ".*" |
			ForEach-Object {

				New-Item -ItemType directory $env:BWCE_HOME\agent -Force | Out-Null
				Expand-Archive -Path $agentFolder\$name -DestinationPath $env:BWCE_HOME\agent

			}

		}

	} catch {

		Write-Error -Exception $PSItem -ErrorAction Stop

	}

}


function Memory-Calculator {

	[CmdletBinding()]
	param()

	try {

		if (-not [string]::IsNullOrEmpty($env:MEMORY_LIMIT)) {

			$memoryNumber = $env:MEMORY_LIMIT -replace "[^0-9]",''
			$configuredMemory = ($memoryNumber * 67 + 50) / 100
			$threadStack = $memoryNumber
			$JAVA_PARAM = "-Xmx" + $configuredMemory + "M -Xms128M -Xss512K"
			$env:BW_JAVA_OPTS = "$JAVA_PARAM $BW_JAVA_OPTS"


		}

	} catch {

		Write-Error -Exception $PSItem -ErrorAction Stop

	}


}

function Check-Libs {

	[CmdletBinding()]
	param()

	try {

		$libFolder = "c:\resources\addons\lib"

		if ((Test-Path $libFolder) -and (Get-ChildItem $libFolder -Exclude .*).Count -gt 0) {

			Print-Debug ("Adding additonal libs")

			Get-ChildItem $libFolder -Exclude ".*" |
			ForEach-Object {

				$name = $_.Name
				$fileExtension = $_.Extension

				if ($fileExtension -eq ".dll") {

					Print-Debug ("DLL file found")
					$JRE_VERSION = Get-ChildItem $env:BWCE_HOME\tibco.home\tibcojre64\* | ForEach-Object { Write-Output $_.Name }
					$JRE_LOCATION = "$env:BWCE_HOME\tibco.home\tibcojre64\$JRE_VERSION"
					$SUNEC_LOCATION = "$JRE_LOCATION\lib\amd64"
					Copy-Item "$libFolder\$name" $SUNEC_LOCATION

				} else {

					New-Item -ItemType directory $env:BWCE_HOME\tibco.home\addons\lib -Force | Out-Null
					Expand-Archive -Path $libFolder\$name -DestinationPath $env:BWCE_HOME\tibco.home\addons\lib
				}


			}


		}


	} catch {

		Write-Error -Exception $PSItem -ErrorAction Stop

	}


}

function Check-ThirdPartyInstallations {

	[CmdletBinding()]
	param()

	try {

		$installFolder = "c:\resources\addons\thirdparty-installs"

		if ((Test-Path $installFolder) -and (Get-ChildItem $installFolder -Exclude .*).Count -gt 0) {

			Print-Debug ("Adding third-party files")

			New-Item -ItemType directory $env:BWCE_HOME\tibco.home\thirdparty-installs -Force | Out-Null

			Get-ChildItem $installFolder -Exclude ".*" |
			ForEach-Object {

				$name = $_.Name
				$fileExtension = $_.Extension

				if (Test-Path -Path $installFolder\$name -PathType Container) {

					Move-Item $installFolder\$name $env:BWCE_HOME\tibco.home\thirdparty-installs | Out-Null

				} elseif ($fileExtension -eq ".zip") {

					$zipFirstName = $name.Split(".")[0]
					Expand-Archive -Path $installFolder\$name -DestinationPath $env:BWCE_HOME\tibco.home\thirdparty-installs\$zipFirstName

				} else {

					Write-Error "Not a valid Zip file used - third party installation" -ErrorAction Stop

				}

			}

		}



	} catch {

		Write-Error -Exception $PSItem -ErrorAction Stop

	}


}

function Setup-ThirdPartyInstallationEnvironment {

	[CmdletBinding()]
	param()

	try {

		$installationDirectory = "$env:BWCE_HOME\tibco.home\thirdparty-installs"

		if ((Test-Path $installationDirectory) -and (Get-ChildItem $installationDirectory -Exclude .*).Count -gt 0) {

			Get-ChildItem $installationDirectory -Exclude ".*" |
			ForEach-Object {

				$name = $_.Name

				if (Test-Path -Path $installationDirectory\$name -PathType Container) {

					if (Test-Path -Path $installationDirectory\$name\lib -PathType Container) {

						#TODO: Check this condition
						$env:LD_LIBRARY_PATH = "$installationDirectory/$name/lib;" + $env:LD_LIBRARY_PATH

					}

					if (Test-Path -Path $installationDirectory\$name\*.ps1 -PathType leaf) {

						$setupFile = "$installationDirectory\$name\*.ps1"
						.$(Get-ChildItem -Path $setupFile)

					}

				}

			}


		}



	} catch {

		Write-Error -Exception $PSItem -ErrorAction Stop

	}


}


$appnodeConfigFile = "$env:BWCE_HOME\tibco.home\bw*\*\config\appnode_config.ini"
$POLICY_ENABLED = "false"
Check-JAVAHOME
Check-JMXConfig
Check-JavaGCConfig

try {

	if (-not (Test-Path -Path "$env:BWCE_HOME\tibco.home" -PathType Container)) {

		Expand-Archive -Path c:\resources\bwce-runtime\bwce*.zip -DestinationPath $env:BWCE_HOME -Force
		Remove-Item c:\resources\bwce-runtime\bwce*.zip -Force 2>$null

		Copy-Item $(Get-ChildItem "$env:BWCE_HOME/tibco.home/bw*/*/bin/bwappnode.tra") "$(Get-ChildItem "$env:BWCE_HOME/tibco.home/bw*/*/bin/bwappnode.tra").bak"
		(Get-Content "$env:BWCE_HOME/tibco.home/bw*/*/bin/bwappnode.tra" | ForEach-Object { $_ -ireplace "_APPDIR_","$env:APPDIR" }) -join "`n" | Set-Content -NoNewline -Force "$env:BWCE_HOME/tibco.home/bw*/*/bin/bwappnode.tra"

		New-Item -ItemType file key.properties | Out-Null
		New-Item -ItemType directory $env:BWCE_HOME\tmp | Out-Null

		$addonFolder = "c:\resources\addons"

		if (Test-Path $addonFolder -PathType Container) {

			Check-Plugins
			Check-Agents
			Check-Libs
			Check-Certs
			#Check-ThirdPartyInstallations

			$jarFolder = "c:\resources\addons\jars"

			Print-Debug ("Copying Addons Jars if present")

			if ((Test-Path $jarFolder) -and (Get-ChildItem $jarFolder -Exclude .*).Count -gt 0) {
				Copy-Item "c:\resources\addons\jars\*" -Destination $(Get-ChildItem -Path "$env:BWCE_HOME\tibco.home\bw*\*\system\hotfix\shared\") -Recurse
				Write-Output "Copied Addons Jars"
			}

		}

		New-Item -ItemType SymbolicLink -Path $(Get-ChildItem -Path "$env:BWCE_HOME\tibco.home\bw*\*\bin\") -Name bwapp.ear -Target C:\*.ear | Out-Null

		Copy-Item $(Get-ChildItem $appnodeConfigFile) "$(Get-ChildItem $appnodeConfigFile).bak"

		<#Get-ChildItem $env:BWCE_HOME\tibco.home\bwce\2.4\config |
			ForEach-Object {
			
				write-output $_.Name
		
			}  #>




		(Get-Content $appnodeConfigFile | ForEach-Object { $_ -ireplace "_APPDIR_","$env:BWCE_HOME" }) -join "`n" | Set-Content -NoNewline -Force $appnodeConfigFile

		Rename-Item $(Get-ChildItem "C:\tmp\tibco.home\bw*\*\bin\bwapp.ear") -NewName bwapp.zip | Out-Null
		Expand-Archive -Path $env:BWCE_HOME\tibco.home\bw*\*\bin\bwapp.zip -DestinationPath C:\tmp -Force | Out-Null
		Rename-Item $(Get-ChildItem "C:\tmp\tibco.home\bw*\*\bin\bwapp.zip") -NewName bwapp.ear | Out-Null

		Set-LogLevel
		Memory-Calculator
		Check-EnvSubstituteConfig

	}

	Check-Profile
	Check-Policy
	#setupThirdPartyInstallationEnvironment

	if ([System.IO.File]::Exists($(Get-ChildItem -Path "C:\*.substvar"))) {

		Copy-Item $(Get-ChildItem -Path "C:\*.substvar") -Destination $env:BWCE_HOME\tmp\pcf.substvar

	} else {

		Copy-Item $env:BWCE_HOME\META-INF\$env:BW_PROFILE -Destination $env:BWCE_HOME\tmp\pcf.substvar
	}

	. $env:JAVA_HOME\bin\java -cp "$(Get-ChildItem "c:\tmp\tibco.home\bw*\*\system\shared\com.tibco.bwce.profile.resolver_*.jar");$(Get-ChildItem "c:\tmp\tibco.home\bw*\*\system\shared\com.tibco.security.tibcrypt_*.jar");$(Get-ChildItem "c:\tmp\tibco.home\bw*\*\system\shared\com.tibco.tpcl.com.fasterxml.jackson_*\*");$(Get-ChildItem "c:\tmp\tibco.home\bw*\*\system\shared\com.tibco.bw.tpcl.encryption.util_*\lib\*");$(Get-ChildItem "c:\tmp\tibco.home\bw*\*\system\shared\com.tibco.bw.tpcl.org.codehaus.jettison_*\*");$env:BWCE_HOME;$env:JAVA_HOME\lib" -DBWCE_APP_NAME="$env:bwBundleAppName" com.tibco.bwce.profile.resolver.Resolver


} catch {
	#$pscmdlet.ThrowTerminatingError($_)
	Write-Output $PSItem -ErrorAction Stop
	throw

}



