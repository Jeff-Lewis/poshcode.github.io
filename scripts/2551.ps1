#==================================================================================================
#              File Name : WSUS-Purge.ps1
#        Original Author : Kenneth C. Mazie (kcmjr)
#            Description : As written it will clear out files left over from Windows Updates.
#                        :
#                  Notes : Normal operation is with no command line options. This PowerShell script
#                        :  is a conversion of a VB script I use to clear out leftover files from
#                        :  Windows Update on XP.  It works on XP, Vista, Win7 and Win2k8 with a 
#                        :  few caveates.  Any OS above the Vista level has changes to the way 
#                        :  installs and updates are stored.  Please see this excellent article for 
#                        :  more info: http://www.winvistaclub.com/f16.html and also the one linked
#                        :  to the bottom of that article.
#                        : 
#              Operation : The script will automatically run with elevated priviledge.  It detects
#                        :  the OS being used as well as the folder it is being executed from.  It 
#                        :  looks for an existing scheduled task to run itself and if not found 
#                        :  creates one.  Once run it will ruthlessly remove most folders named 
#                        :  "$ntuninstall...$" in "C:\Windows" (on XP) as well as the associated 
#                        :  registry keys in "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"
#                        :  (on XP) and the files stored in "C:\Windows\SoftwareDistribution\Download"
#                        :  (all OS vers).  All KB log files are also removed from "C:\windows".  OS 
#                        :  version is also detected and noted in the output (included for future use).
#                        :
#                        :  All destructive operations are disabled by default.  Comment out the 
#                        :   "-whatif" statements to enable active processing.  Tested on XP and Win7.
#                        :
#               Warnings : Use of this script will gain you disk space on C: but will make
#                        :   uninstalling of patches nearly impossible.  See below.
#                        :
#	           Legal : Public Domain.  Modify and redistribute freely.  No rights reserved.
#              	         : SCRIPT PROVIDED "AS IS" WITHOUT WARRANTIES OR GUARANTEES OF ANY KIND.
#                        : USE AT YOUR OWN RISK. NO TECHNICAL SUPPORT PROVIDED.
#                        :   
#         Last Update by : Kenneth C. Mazie 
#        Version History : v1.0 - 12-08-10 - Original 
#         Change History : v2.0 - 12-09-10 - Added options to automatically set a scheduled task to
#                        :   run the script on a random day and time.
#
#==================================================================================================

Clear-Host
$ErrorActionPreference = "SilentlyContinue"
$rand = New-Object  System.Random

#--[ Execute with admin priviledge ]--
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = new-object Security.Principal.WindowsPrincipal $identity
if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)  -eq $false) {
  $Args = '-noprofile -nologo -executionpolicy bypass -file "{0}"' -f $MyInvocation.MyCommand.Path
  Start-Process -FilePath 'powershell.exe' -ArgumentList $Args -Verb RunAs
  exit
}
write-host "Running with Admin Privileges"
#Read-Host "PRESS ENTER"

#--[ Get script folder ]--
function Get-ParentFolderOfThisScript
{
    $ParentProcessInvocation = Get-Variable MyInvocation -Scope 1
    $InvocationInfo = $ParentProcessInvocation.Value
    $CommandInfo = $InvocationInfo.MyCommand
    $FullPathToThisScript = $CommandInfo.Path
    Split-Path $FullPathToThisScript -parent
}

#--[ Create the scheduled task ]--
Function Create-ScheduledTask
{
param(
	[string]$ComputerName = "localhost",
	[string]$RunAsUser = "System",
	[string]$RunLevel = "HIGHEST",
	[string]$TaskName = "WSUS-Purge",
	[string]$TaskRun = "'powershell.exe -nologo -noninteractive -file $scriptpath\WSUS-Purge.ps1'",
#	[string]$TaskRun = "powershell.exe -nologo -noninteractive -command `"& {$scriptpath\WSUS-Purge.ps1}`"",
	[string]$Schedule = "Weekly",
	[string]$Modifier = "second",
	[string]$Days = (($Array = "SUN","MON","TUE","WED","THU","FRI","SAT" ) | Get-Random),
	[string]$Months = '"MAR,JUN,SEP,DEC"',
	[string]$StartTime = "$("{0:D2}" -f $rand.next(0,23)):$("{0:D2}" -f $rand.next(0,59))",
	[string]$EndTime = "02:00",
	[string]$Interval = "60"	
	)
 Write-Host "Creating new task..."
 write-host "Time set to $time..."
 Write-Host "Day set to $Days..."
 #$Command = "schtasks.exe /create /s $ComputerName /ru $RunAsUser /tn $TaskName /tr $TaskRun /sc $Schedule /mo $Modifier /d $Days /m $Months /st $StartTime /et $EndTime /ri $Interval /F"
 if ($($os.version.Split(".")[0]) -ge 6){
 #--[ Run for Vista and higher ]--
 $Command = "schtasks.exe /create /s $ComputerName /ru $RunAsUser /rp $RunAsPwd /rl $RunLevel /tn $TaskName /tr $TaskRun /d $Days /sc $Schedule /st $StartTime /F"
} else {
 #--[ Remove runlevel option for 2003 and lower ]--
 $Command = "schtasks.exe /create /s $ComputerName /ru $RunAsUser /rp $RunAsPwd /tn $TaskName /tr $TaskRun /d $Days /sc $Schedule /st $StartTime /F"
}
 Invoke-Expression $Command
 Clear-Variable Command -ErrorAction SilentlyContinue
 }

#--[ Manage Scheduled Task ]--
$scriptpath = Get-ParentFolderOfThisScript
$time = "$("{0:D2}" -f $rand.next(0,23)):$("{0:D2}" -f $rand.next(0,59))"
if ($task = Schtasks.exe /query /s "localhost" /v /FO CSV | select-string -pattern â€œWSUS-Purgeâ€) {
Write-Host "Task already exists..."
} else {
Create-ScheduledTask -StartTime $($time)
}

#--[ Get Windows version ]--
switch ($os.version)
  {
    "5.1.2600" {Write-Host "Running on Windows XP"}
    "5.2.3790" {Write-Host "Running on Windows Server 2003"}
	"6.0.6000" {Write-Host "Running on Windows Vista"}
	"6.0.6001" {Write-Host "Running on Windows Server 2008"}
    "6.1.7600" {Write-Host "Running on Windows 7 or Server 2008 R2"}
    default {"The operating system could not be determined."}
  }

#--[ Get %windir% environemnt variable ]--
$windir = [System.Environment]::ExpandEnvironmentVariables("%WINDIR%")
#--[ Alternate format ]-- #$windir = $env:windir

#--[ Read existing patch folders in %windir% ]--
$dirs = Get-ChildItem $windir -Force | Where-Object { $_.PSIsContainer } | Select-Object Name | Where-Object {$_.Name -like "`$ntuninstallkb*" -or $_.Name -like "$ntuninstallq"} 
if ($dirs.count -gt 0) {
  write-host $dirs.count " patches to process"
  foreach ($dir in $dirs) {

    $patch = ($($dir.Name).Remove(0,12)).Replace("$", "")
    Write-Host "Processing " $patch
  
    #--[ Delete the registry key ]--
    Remove-Item -Path "HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$patch" -recurse -Force -whatif
      #--[ Alternate format ]-- #Get-ChildItem -path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall | Where-Object {$_.PSChildName -eq $patch } | Remove-Item -Force -WhatIf 

    #--[ Delete the uninstall folder ]--
    Remove-Item "$windir\$($dir.name)" -recurse -Force -whatif
      #--[ Alternate format ]-- #Get-ChildItem -path $windir | Where-Object {$_.PSChildName -eq $($dir.name)} | Remove-Item -Force -WhatIf 
}} else {
  write-host "No C:\Windows patch folders to process..."
}

#--[ Remove left over KB log files ]--
write-host "Removing patch logs..."
Remove-Item "$windir\kb*.log" -recurse -Force -whatif

#--[ Remove items stored in the C:|windows\SoftwareDistribution\Download folder ]--
write-host "Purging downloaded patches..."
Get-childitem $windir\SoftwareDistribution\Download\* -recurse | remove-item -recurse -force -whatif 

#--[ Remove items stored in the C:|windows\Installer folder.  Disabled by default.  May cause applications to malfunction. ]--
#Get-childitem $windir\Installer\* -recurse | remove-item -recurse -force  -whatif 


