#Requires -Version 3.0

#This script is designed to be attached to Windows TS Events 21 and 22 (which work for local logons too) 
#to email notification to an audit mailbox

#Author: Justin Grote <jgrote@allieddigital.net>

#USAGE: Send-LogonNotifyEmail.ps1 <LogAction> <EmailRecipient>

#EXAMPLE: Attach to event ID 21 using event viewer GUI, and have the script run as Send-LogonNotifyEmail.ps1 logon audit@mycompany.com   
#EXAMPLE 2: Attach to event ID 23 using event viewer GUI, and have the script run as Send-LogonNotifyEmail.ps1 logon audit@mycompany.com   


#Variables
if (!$PSEmailServer) {$PSEmailServer = "mail"}
$logaction = $args[0]
$msgRecipient = $args[1]


#Get the FQDN of the server
$ComputerName = [System.Net.Dns]::GetHostByName(($env:computerName)).HostName.ToLower()

#Script
switch ($logaction) {
    logon {$ActionEventID = 21}
    logoff {$ActionEventID = 23}
}

$EventToSend = get-winevent -maxevents 1 -filterhashtable  @{ LogName = "Microsoft-Windows-TerminalServices-LocalSessionManager/Operational";ID = $ActionEventID }

###Construct the Email and Send it

#Extract username from Event Log body and do some cleanup.
$targetUser = ($EventToSend.message.split("`n") | select-string "User:").ToString().substring(6).Normalize()

#Trim the last character. I can't figure out what it is but it is not compatible as an email subject item
$targetuser = $targetuser.substring(0,$targetuser.length-1)

#Message Subjects have to be sanitized, hence the "replace" statements at the end
$msgSubject = ("Notification: $targetuser $logaction - $computername").Replace('`r', ' ').Replace('`n', ' ')

$msgBody = "$($EventToSend.TimeCreated) 
$($eventToSend.message.Replace('`n', '`r`n'))"

#Deliver Email
send-mailmessage -To $msgRecipient -Subject $msgSubject -Body $msgBody -From "scheduledtask@$computername"

###End
