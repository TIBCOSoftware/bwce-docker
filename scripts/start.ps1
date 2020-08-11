$ProgressPreference = "SilentlyContinue"
#!/bin/bash
#Set ENV Variables
$env:BWCE_HOME = "c:/tmp"
$env:APPDIR = $env:BWCE_HOME
$env:MALLOC_ARENA_MAX = 2
$env:MALLOC_MMAP_THRESHOLD_ = 1024
$env:MALLOC_TRIM_THRESHOLD_ = 1024
$env:MALLOC_MMAP_MAX_ = 65536
$env:BW_KEYSTORE_PATH = "c:\resources\addons\certs"
#$env:BW_HOME="c:\tmp\tibco.home\bwce\2.4"

try {
	. "C:\scripts\install-ssh.ps1"
	. "C:\scripts\setup.ps1"
	#. c:\tmp\tibco.home\bwce\2.4\bin\bwappnode.exe --propFile c:\tmp\tibco.home\bwce\2.4\bin\bwappnode.tra -profileFile c:\tmp\tmp\pcf.substvar  -ear C:\tmp\tibco.home\bwce\2.4\bin\bwapp.ear -config c:\tmp\tibco.home\bwce\2.4\config\appnode_config.ini -l admin startlocal 
	$bwceFolderVersion = Get-ChildItem c:\tmp\tibco.home\bwce\* | ForEach-Object { Write-Output $_.Name }
	$env:BW_HOME = "c:\tmp\tibco.home\bwce\$bwceFolderVersion"
	.$(Get-ChildItem c:\tmp\tibco.home\bw*\*\bin\bwappnode.exe) --propFile $(Get-ChildItem c:\tmp\tibco.home\bw*\*\bin\bwappnode.tra) -profileFile c:\tmp\tmp\pcf.substvar -ear $(Get-ChildItem C:\tmp\tibco.home\bw*\*\bin\bwapp.ear) -config $(Get-ChildItem c:\tmp\tibco.home\bw*\*\config\appnode_config.ini) -l admin startlocal

} catch {

	Write-Output "ERROR: Failed to setup BWCE runtime. See logs for more details."
	Write-Error "Ran into an issue: $PSItem" -ErrorAction Stop
	exit 1

}