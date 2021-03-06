# Fix the VPC options left and top position for console

$today = get-date -Format "yyyyMMdd"
$now = Get-Date -format "hhmmss"
$today_now = Get-Date -format "yyyyMMdd_hhmmss"

@"

Fix the Virtual PC Console options for left and top position "

Makes a backup copy of "${env:appdata}\Microsoft\Virtual PC\Options.xml") 
And calls it "${env:appdata}\Microsoft\Virtual PC\Options_${today_now}.xml"

"@

copy-item ("${env:appdata}\Microsoft\Virtual PC\Options.xml") ("${env:appdata}\Microsoft\Virtual PC\Options_${today_now}.xml")

[XML]$opt = get-content ("${env:appdata}\Microsoft\Virtual PC\Options.xml") -Encoding unicode

$opt.preferences.window.console.left_position.set_InnerText("20")
$opt.preferences.window.console.top_position.set_InnerText("20")

$opt.Save("${env:appdata}\Microsoft\Virtual PC\Options.xml")

# TODO: Fix save as unicode
