function Get-InstalledProgram() {
param (
[String[]]$Computer,
$User
)
#############################################################################################
if ($User) {$Connection = Get-Credential -Credential $User}
#############################################################################################
if (!$Connection){
	foreach ($Comp in $Computer){
		$Install_soft = gwmi win32_product -ComputerName $Comp | where {$_.vendor -notlike "*Microsoft*" -and $_.vendor -notlike "*PGP*" -and $_.vendor -notlike "*Intel*" -and $_.vendor -notlike "*Corel*" -and $_.vendor -notlike "*Adobe*" -and $_.vendor -notlike "*ABBYY*" -and $_.vendor -notlike "*Sun*" -and $_.vendor -ne "SAP" -and $_.vendor -ne "Marvell" -and $_.vendor -ne "Hewlett-Packard"} | Format-Table __SERVER,Name,Version,InstallDate
		$Install_soft
	}
}
else {
	foreach ($Comp in $Computer){	
		$Install_soft = gwmi win32_product -ComputerName $Comp -Credential $Connection | where {$_.vendor -notlike "*Microsoft*" -and $_.vendor -notlike "*PGP*" -and $_.vendor -notlike "*Intel*" -and $_.vendor -notlike "*Corel*" -and $_.vendor -notlike "*Adobe*" -and $_.vendor -notlike "*ABBYY*" -and $_.vendor -notlike "*Sun*" -and $_.vendor -ne "SAP" -and $_.vendor -ne "Marvell" -and $_.vendor -ne "Hewlett-Packard"} | Format-Table __SERVER,Name,Version,InstallDate
		$Install_soft
	}
}
}
