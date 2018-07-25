function setConfig( $file, $key, $value ) {
    $content = Get-Content $file

    if ( $content -match "$key\s*=" ) {
        $content -ireplace "$key\s*=.*", "$key = `"$value`">" |
        Set-Content $file     
        
    } else {
    
        Add-Content $file "$key = $value"  
    
    }
}



setConfig "C:\bwce\bwce-docker\scripts\logback.xml" "<root level" "error"