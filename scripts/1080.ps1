###############################################################################
# 
# Get all servers from a OU and run GPUpdate /force on this machines.
# 
# Version 1.0
#
# (C) 2009 - Arne Fokkema
# www.ict-freak.nl 
#
# Install the Quest AD cmdlets first!!
# 
###############################################################################

# Requires QAD cmdlets
if ((Get-PSSnapin "Quest.ActiveRoles.ADManagement" `
            -ErrorAction SilentlyContinue) -eq $null) {
    Add-PSSnapin "Quest.ActiveRoles.ADManagement"
}

$url = "http://live.sysinternals.com/psexec.exe"
$target = "c:\Tools\psexec.exe"
$TempFile = "C:\Machines.txt"
$Domain = Read-Host ("Enter the FQDN of the Domain")
$OU = Read-Host ("Enter the name of the OU")

# Check if psexec does exist
if (test-path $target)
{
write-host "psexec.exe is already installed"
} 
else
{
write-host "psexec.exe doesn't exist"
$wc = New-Object System.Net.WebClient
$wc.DownloadFile($url, $target);
write-host "psexec.exe is now installed"
}


$Servers = Get-QADComputer -SearchRoot $Domain/$OU | Select Name | out-file $TempFile -force

#Cleanup Textfile
(Get-Content $TempFile) | Foreach-Object {$_ -replace "Name                                                                           ", ""} | Set-Content $TempFile
(Get-Content $TempFile) | Foreach-Object {$_ -replace "----                                                                           ", ""} | Set-Content $TempFile
(Get-Content $TempFile) | Foreach-Object {$_ -replace "                                                                       ", ""} | Set-Content $TempFile
(Get-Content $TempFile) | where {$_ -ne ""} >$TempFile

$colComputers = Get-Content $TempFile
Foreach ($strComputer in $colComputers){c:\Tools\psexec.exe \\$strComputer gpupdate.exe /target:computer /force}
	
RM $TempFile
