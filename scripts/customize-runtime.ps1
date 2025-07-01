# Requires -Version 5.0
$ErrorActionPreference = "Stop"
$REDUCED = $env:REDUCED_STARTUP_TIME
if (-not $REDUCED) { $REDUCED = "false" }

if ($REDUCED -ne "true" -and
     $env:EXCLUDE_GOVERNANCE -eq "false" -and
     $env:EXCLUDE_CONFIG_MANAGEMENT -eq "false" -and
     $env:EXCLUDE_JDBC -eq "false") {
     Write-Host "No changes required to runtime zip. Skipping customization."
     exit 0
 }

Get-ChildItem -Path "C:/app/resources/bwce-runtime/bwce-runtime*.zip" | ForEach-Object {
    $f = $_.FullName

    if (Test-Path "tmp") { Remove-Item -Recurse -Force "tmp" }
    Expand-Archive -Path $f -DestinationPath "tmp"

    # Remove governance features if exclude is true
    if ($env:EXCLUDE_GOVERNANCE -eq "true") {
        Get-ChildItem -Path "tmp" -Recurse -Directory -Filter "com.tibco.governance*" | Remove-Item -Recurse -Force 
        Get-ChildItem -Path "tmp" -Recurse -File -Filter "com.tibco.governance*" | Remove-Item -Force
        Get-ChildItem -Path "tmp" -Recurse -Directory -Filter "org.hsqldb*" | Remove-Item -Recurse -Force
    }

    # Remove config management features if exclude is true
    if ($env:EXCLUDE_CONFIG_MANAGEMENT -eq "true") {
        Get-ChildItem -Path "tmp" -Recurse -File -Filter "com.tibco.configuration.management.services*" | Remove-Item -Force
    }

    #Remove all JDBC drivers if exclude is true
    if ($env:EXCLUDE_JDBC -eq "true") {
        $jdbcDirs = @(
            "com.tibco.bw.tpcl.jdbc.datasourcefactory.mariadb*",
            "com.tibco.bw.tpcl.jdbc.datasourcefactory.postgresql*",
            "com.tibco.bw.tpcl.jdbc.datasourcefactory.sqlserver*",
            "com.tibco.bw.tpcl.jdbc.datasourcefactory.oracle*"
        )
        foreach ($pattern in $jdbcDirs) {
            Get-ChildItem -Path "tmp" -Recurse -Directory -Filter $pattern | Remove-Item -Recurse -Force
        }
    }

    # Re-zip the modified runtime if reduced startup time is false
    if ($REDUCED -ne "true") {
        Write-Host "reduced startup time is false"
        Set-Location "tmp"
        Get-ChildItem | Write-Host
        Write-Host "Compressing files into tmp.zip in C:/app"
        Compress-Archive -Path * -DestinationPath "C:/app/tmp.zip" -Force
        Set-Location ..
        Move-Item -Force "C:/app/tmp.zip" $f
        Remove-Item -Recurse -Force "tmp"
    }
}