<#
Author: James Day
Created: 31st October 2013

Original script source taken from http://gallery.technet.microsoft.com/scriptcenter/WSB-Backup-network-email-9793e315
Full Credit goes to the Original author Augagneur Alexandre. Without your initial script I wouldn't have got this far.

Tested on Server 2012 using Powershell version 3.0

USE AT YOUR OWN RISK.
#>
#Initialize WSB cmdlets
Import-Module WindowsServerBackup
 
#------------------------------------------------------------------ 
#Variables 
#------------------------------------------------------------------  
 
#Files server 
$Nas = "\\NAS" 
 
#Root folder 
$HomeBkpDir = ($Nas+"\BACKUP") 
 
#Backup folder 
$Filename = Get-Date -Format yyyy-MM-dd_hhmmss
 
#Number of backup to retain (value "0" disable rotation) 
$MaxBackup = 2
 
#List uncritical volumes 
$Volumes = Get-WBVolume -AllVolumes | Where-Object { $_.Property -notlike "Critical*" } 
  
#------------------------------------------------------------------  
#Function to compare the number of folders to retain with 
#$MaxBackup (Not called if $MaxBackup equals 0) 
#------------------------------------------------------------------  
function Rotation() 
{  
 #List all backup folders 
 $Backups = @(Get-ChildItem -Path $HomeBkpDir | Sort-Object -property Name) 
 
 #Number of backups folders 
 $NbrBackups = $Backups.count 
 
 $i = 0 
  
 #Delete oldest backup folders 
 while ($NbrBackups -ge $MaxBackup) 
 { 
  #The orignal script included the -force switch when calling remove-item but this gave me errors YMMV
  $($Backups[$i].fullname) | Remove-Item -Recurse
  $NbrBackups -= 1 
  $i++ 
 } 
} 
  
#------------------------------------------------------------------ 
#Function to send email notification 
#------------------------------------------------------------------  
function EmailNotification() 
{ 
 Start-Sleep -Seconds 120
 #Sender email 
 $from = "backup@example.com" 
 
 #Receipt email 
 $to = "postmaster@example.com" 
 
 #SMTP Server 
 $smtpserver = "server" 
  
 #Mail subject 
 $Subject = $env:computername+": Backup report of "+(Get-Date) 
  
 #Prepare Mail content
 $report = get-wbjob -previous 1 
 $success = $report.SuccessLogPath
 $Failure = $report.FailureLogPath
 $body = "Success and Failure logs are attached" 

 #Sends the message 
 Send-MailMessage -to $to -from $from  -subject $Subject -body $body -attachments $success,$failure -smtpserver $smtpserver
} 
 
#------------------------------------------------------------------ 
#Main 
#------------------------------------------------------------------  
 
#Execute rotation if enabled 
if ($MaxBackup -ne 0) 
{ 
 Rotation 
} 
  
#Backup folder creation 
New-Item ($HomeBkpDir+"\"+$Filename)  -Type Directory | Out-Null 
  
$WBPolicy = New-WBPolicy 
  
#Enable BareMetal functionnality (system state included) 
Add-WBBareMetalRecovery -Policy $WBPolicy | Out-Null 
  
#Add backup target 
$BackupLocation = New-WBBackupTarget -network ($HomeBkpDir+"\"+$Filename) 
Add-WBBackupTarget -Policy $WBPolicy -Target $BackupLocation -force | Out-Null 
  
#Add uncritical volumes 
if ($Volumes -ne $null) 
{ 
 Add-WBVolume -Policy $WBPolicy -Volume $Volumes | Out-null 
} 
#Make this a full VSS backup as opposed to a copy backup. This will truncate Exchange logs etc...
Set-WBVssBackupOptions -policy $WBPolicy -vssfullbackup | Out-null

#Displays the backup settings prior to running the job.
$WBPolicy

#Runs the backup task.
Start-WBBackup -Policy $WBPolicy 
  
#Call email notification function 
EmailNotification
