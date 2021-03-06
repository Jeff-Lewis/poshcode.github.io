#* FileName: loginTime.ps1
#*=============================================================================
#* Created: [09/25/2009]
#* Author: Alan Oakland
#*=============================================================================
#* Purpose: Create a log of login times.
#*=============================================================================

#*=============================================================================
#* REVISION HISTORY
#*=============================================================================

#*=============================================================================

#*=============================================================================
#* Variable Configuration
#*=============================================================================
$adsobj = [ADSI]"WinNT://$domain/$env:username"
$logpath = "\\server\share\path"
#*=============================================================================
#* FUNCTION LISTINGS
#*=============================================================================

#*=============================================================================
#* SCRIPT BODY
#*=============================================================================
#Retrieve IP information
$global:ipinfo = get-wmiobject -class "Win32_NetworkAdapterConfiguration" `
| Where{($_.IpEnabled -Match "True") -And ($_.DNSDomain -Match $curDomain)}
if ($ipinfo)
{
  $global:ip=$ipinfo.ipaddress[0]
}
else
{
  $global:ip=[system.net.dns]::gethostAddresses($null)[0].ipaddresstostring
  if (!($ip))
  {
    $global:ip="IP could not be resolved"
  }
}



$fullName = $adsobj.FullName.value.toString()
$logfile = "$($logpath)\USER-$fullname.ini" # this is the log file
$recordstokeep = 200 # set this to the number of user records to keep
#Create the logfile if it doesn't exist 
if (!(test-path -path "$logfile"))
{
  $null = new-item $logfile -Type file
}
# write the log entry
$logData = "$(get-date -Format M/dd/yyyy) - $(get-date -Format H:mm:ss) - Login  - $ip - $env:username - $env:clientname=$env:computername"
# read all the log entries into an array
[Array]$entries = Get-Content $logfile
#Add the data to the array
$entries += $logData
if (($entries.length-1) -gt $recordstokeep)
{
  #delete anything less than required number of days
  $entries = $entries[0],$entries[($entries.length-$recordstokeep)..($entries.length-1)]
}
#Write Output
$entries | Out-File $logfile

#Computer Log
$logfile = "$($logpath)\COMP-$env:computername.ini" #this is the log file 
$recordstokeep = 200 # set this to the number of computer records to keep
#Create the logfile if it doesn't exist 
if (!(test-path -path "$logfile"))
{
  $null = new-item $logfile -Type file
}
# write the log entry
$logData = "$(get-date -Format yyyy/M/dd) - $(get-date -Format H:mm:ss) - Login  - $ip - $env:username =$fullName"
# read all the log entries into an array
[Array]$entries = Get-Content $logfile
#Add the data to the array
$entries += $logData
if (($entries.length-1) -gt $recordstokeep)
{
  #delete anything less than required number of days
  $entries = $entries[0],$entries[($entries.length-$recordstokeep)..($entries.length-1)]
}
#Write Output
$entries | Out-File $logfile
#*=============================================================================
#* END OF SCRIPT
#*=============================================================================

