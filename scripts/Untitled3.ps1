$BW_LOGLEVEL = "debug"

function print_Debug( $message ) {

	if ( -not [String]::IsNullOrEmpty($BW_LOGLEVEL) -and $BW_LOGLEVEL.ToLower() -eq "debug" ) {
	
		write-host $message
	
	}

}

print_Debug("nitish")

write-host $?

Get-Content (C:\bwce\bwce-docker\scripts\MANIFEST.MF).replace(‘-Djava.class.path=’, ‘MyValue’) | Set-Content -NoNewline C:\bwce\bwce-docker\scripts\MANIFEST.MF


$logback=C:\bwce\bwce-docker\scripts\logback.xml

function setConfig( $file, $key, $value ) {
    $content = Get-Content $file
    if ( $content -match "^$key\s*=" ) {
        $content -replace "^$key\s*=.*", "$key = $value" |
        Set-Content $file     
        echo "boo-yeah"
    }
}

setConfig($logback, "root", "Error")


(Get-Content $logback | ForEach-Object {$_ -replace "/<root/ ".*", "$BW_LOGLEVEL"}) -join “`n” | Set-Content -NoNewline -Force $logback