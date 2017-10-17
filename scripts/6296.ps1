﻿# Prompt for Search String
$Input = Read-Host	'Dot-sourced path to input file (eg .\Targets.txt)'
Write-Host		' '
Write-Host		'Wildcard characters * and ? can be used in the pattern'
Write-Host		' '
$Include = Read-Host	'Include profiles that match this naming pattern'
$Exclude = Read-Host	'Exclude profiles that match this naming pattern'

$Date = Get-Date -Format yyyyMMdd.hhmm
$Targets = Get-Content $Input
foreach ($target in $Targets) {

	delprof2 /l /c:\\$target /ed:$Exclude /id:$Include >> .\Delprof_$Date.log	## LIST profiles
	# delprof2 /c:\\$target /ed:$Exclude /id:$Include >> .\Delprof_$Date.log	## REMOVE profiles
}

# Wait for user acknowledgement
Write-Host -NoNewLine "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
