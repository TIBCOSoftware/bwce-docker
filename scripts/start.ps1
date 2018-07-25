#!/bin/bash
#Set ENV Variables
$env:BWCE_HOME="c:/tmp"
$env:APPDIR=$env:BWCE_HOME
$env:MALLOC_ARENA_MAX=2
$env:MALLOC_MMAP_THRESHOLD_=1024
$env:MALLOC_TRIM_THRESHOLD_=1024
$env:MALLOC_MMAP_MAX_=65536
$env:BW_KEYSTORE_PATH="c:\resources\addons\certs"
$env:BW_HOME="c:\tmp\tibco.home\bwce\2.3"
echo "********I came till here************"
#echo $env:APPDIR
#echo $env:BWCE_HOME
#. "C:\scripts\setup2.ps1"




<#Get-Module -ListAvailable |
Where-Object ModuleBase -like $env:ProgramFiles\WindowsPowerShell\Modules\* |
Sort-Object -Property Name, Version -Descending |
Get-Unique -PipelineVariable Module |
ForEach-Object {
    if (-not(Test-Path -Path "$($_.ModuleBase)\PSGetModuleInfo.xml")) {
        Find-Module -Name $_.Name -OutVariable Repo -ErrorAction SilentlyContinue |
        Compare-Object -ReferenceObject $_ -Property Name, Version |
        Where-Object SideIndicator -eq '=>' |
        Select-Object -Property Name,
                                Version,
                                @{label='Repository';expression={$Repo.Repository}},
                                @{label='InstalledVersion';expression={$Module.Version}}
    }
}#>


#Import-Module Microsoft.PowerShell.Archive
#Get-Module Microsoft.PowerShell.Archive
#Install-PackageProvider -Name "Nuget" -RequiredVersion "2.8.5.216" -Force
#Update-Module -Name "Microsoft.PowerShell.Archive" -Force

#Install-PackageProvider NuGet -Force
#Import-PackageProvider NuGet -Force
#Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
#Update-Module -Name "Microsoft.PowerShell.Archive" 


try {
	. "C:\scripts\setup2.ps1"
	. c:\tmp\tibco.home\bwce\2.3\bin\bwappnode.exe --propFile c:\tmp\tibco.home\bwce\2.3\bin\bwappnode.tra -profileFile c:\tmp\tmp\pcf.substvar  -ear C:\tmp\tibco.home\bwce\2.3\bin\bwapp.ear -config c:\tmp\tibco.home\bwce\2.3\config\appnode_config.ini -l admin startlocal 
	
} catch {
	
	echo "ERROR: Failed to setup BWCE runtime. See logs for more details."
	Write-Error  "Ran into an issue: $PSItem" -ErrorAction Stop
	Exit 1

}


<# echo "********Printing DIR 2************"
foreach ($entry in Get-ChildItem "c:/tmp/tibco.home/bwce/2.3/bin") {
	
	 write-host $entry

}
	
cd c:/tmp/tibco.home/bwce/2.3/bin

#./bwappnode.exe --propFile ./bwappnode.tra -ear ./bwapp.ear -l admin startlocal --config c:/tmp/tibco.home/bwce/2.3/config/appnode_config.ini
c:/tmp/tibco.home/bwce/2.3/bin/bwappnode.exe --propFile c:/tmp/tibco.home/bwce/2.3/bin/bwappnode.tra -profileFile c:/tmp/tmp/pcf.substvar  -ear c:/tmp/tibco.home/bwce/2.3/bin/bwapp.ear -config c:/tmp/tibco.home/bwce/2.3/config/appnode_config.ini -l admin startlocal #>