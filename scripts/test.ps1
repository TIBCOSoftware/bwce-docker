function checkProfile2 {

		echo "chal jaa"
		$BUILD_DIR=$env:BWCE_HOME
		$manifest=$BUILD_DIR+"\META-INF\MANIFEST.MF"
		$bwAppConfig="TIBCO-BW-ConfigProfile"
		$bwAppNameHeader="Bundle-SymbolicName"
		$bwEdition="bwcf"
		$bwEditionTest = select-string $bwEdition $manifest 
		
		if ($bwEditionTest) {write-host "not empty"} 		
		
		
		<# if ( [System.IO.File]::Exists($manifest) ) { 
			
			$bwAppProfileStr = select-string $bwAppConfig+".*.substvar" $manifest | ForEach-Object Line
			echo $bwAppProfileStr
			#$bwBundleAppName=`while read line; do printf "%q\n" "$line"; done<${manifest} | awk '/.*:/{printf "%s%s", (NR==1)?"":RS,$0;next}{printf "%s", FS $0}END{print ""}' | grep -o $bwAppNameHeader.* | cut -d ":" -f2 | tr -d '[[:space:]]' | sed "s/\\\\\r'//g" | sed "s/$'//g"`
			$bwBundleAppName = select-string $bwAppNameHeader $manifest | %{$_.Line.Split(":")[1]}
			echo $bwBundleAppName
		
			
			if ( $env:DISABLE_BWCE_EAR_VALIDATION -ne "True" ) {
			
				echo "muahaha"
			
			}
		} #>
		
		Get-ChildItem $BUILD_DIR |
			ForEach-Object {
			
				$name = $_.Name
                
				echo $name
				
				
				
			}
	

}

checkProfile2
echo "here" + $bwEdition
