###########################################################################"
#
# NAME: Backup-ModifiedGPOs.ps1
#
# AUTHOR: Jan Egil Ring
# EMAIL: jan.egil.ring@powershell.no
#
# COMMENT: All Group Policy Objects modified in the specified timespan are backup up to the specified backup path.
#          For more details, see the following blog-post: 
#          http://blog.powershell.no/2010/06/15/backing-up-group-policy-objects-using-windows-powershell
#
# You have a royalty-free right to use, modify, reproduce, and
# distribute this script file in any way you find useful, provided that
# you agree that the creator, owner above has no warranty, obligations,
# or liability for such use.
#
# VERSION HISTORY:
# 1.0 15.06.2010 - Initial release
#
# 1.1 17.11.2010 - Andy Helsby - Added check to create backup directory and report directory if it does not exist.
#                - Added optional parameter to allow backups of gpo's modified in last X days (defaults to 1 otherwise)
#                - Note if no group policies were modified in the previous X days, the script does throw an error about Name not being provided.
#
# 1.2 24.11.2010 - Added the -FirstRun switch parameter to backup all GPO`s. Added additional logic.
###########################################################################"

#Requires -Version 2.0

Param([switch]$FirstRun)

Import-Module grouppolicy

$BackupPath = "C:\GPO Backup"
$ReportPath = "C:\GPO Backup\Reports\"
if (!(Test-Path -path $BackupPath)) {New-Item $BackupPath -type directory}
if (!(Test-Path -path $ReportPath)) {New-Item $ReportPath -type directory}

if ($FirstRun) {
$Timespan = (Get-Date).AddDays(-5000)
}
else {
$Timespan = (Get-Date).AddDays(-1)
}

$ModifiedGPOs = Get-GPO -all | Where-Object {$_.ModificationTime -gt $Timespan}

if ($ModifiedGPOs) {

Write-Host "The following "$ModifiedGPOs.count" GPOs were successfully backed up:" -ForegroundColor yellow

Foreach ($GPO in $ModifiedGPOs) { 

    $GPOBackup = Backup-GPO $GPO.DisplayName -Path $BackupPath
    $Path = $ReportPath + $GPO.ModificationTime.Month + "-"+ $GPO.ModificationTime.Day + "-" + $GPO.ModificationTime.Year + "_" +  

$GPO.Displayname + "_" + $GPOBackup.Id + ".html" 
    Get-GPOReport -Name $GPO.DisplayName -path $Path -ReportType HTML

    Write-Host $GPO.DisplayName
}
}
else {
Write-Host "No GPO`s modified since $Timespan. If this is your initial backup, run the script with the -FirstRun switch parameter to backup all GPO`s" -ForegroundColor yellow
}
