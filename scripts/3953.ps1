<#
.SYNOPSIS
Get-InactiveActiveSyncDevices pulls all user mailboxes with an Active Sync partnership and then selects the Active Sync devices that haven't synced in the specified period. These devices are sorted in ascending order and placed in a HTML table which is emailed to the specified user using a specified reply to address and SMTP server
PLEASE TEST BEFORE RUNNING THIS SCRIPT IN PRODUCTION
.DESCRIPTION
The script 1st checks to see if Implicit remoting is needed to load the required PSsnapin (Microsoft.Exchange.Management.PowerShell.E2010), this is done by seeing it the $ExchangeConnectionUri variable does not have a $NULL value. If it contains a URI then create a new PSsession using the current credentials and import the session. If Implict remoting isn't needed then verify that the required PSsnapin (Microsoft.Exchange.Management.PowerShell.E2010) is loaded and if not try to load it locally. Then  Get-InactiveActiveSyncDevices uses Get-CasMailbox to pull all the user mailboxes (Not Discovery or CAS mailboxes) with Active Sync device partnerships and saves them to a variable called $ActiveSyncMailboxes. It then walks through each mailbox and uses Get-ActiveSyncDeviceStatistics to pull DeviceType, DeviceUserAgent, DeviceID, LastSyncAttemptTime, LastSuccessSync for each mailbox’s separate Active Sync device partnership and puts these properties in addition to the full name associated with the mailbox into a hashtable called $UserActiveSyncStats. The reason why Get- ActiveSyncDeviceStatistics isn’t used exclusively is because it does not have a property that stores just the name of the user who owns the Active Sync device, only a full Active Directory path to the Active Sync device. This hash table is used to create a custom PowerShell Object which is then added to $ActiveSyncDeviceList. A variable called $MatchingActiveSyncDevices holds all the Active Sync devices in $ActiveSyncDeviceList that haven’t synced to the Exchanger server in less than or equal to the number of hours specified in $HourInterval . $MatchingActiveSyncDevices is then checked to see if it’s an empty array or not. If it contains items an HTML header is created to format the table for the HTML email report and saved in a variable called $HTMLHeader . Then The Body of the email contains all of the criteria matching Active Sync devices from $MatchingActiveSyncDevices in ascending order which is converted to HTML using the HTML header information created earlier in $HTMLHeader. Otherwise a the body contains a message stating that no devices matched the given criteria.. An Email is then sent out to the user specified in $to from the address specified in $from using the email server specified in $SmtpServer. The body is generated from the sorted Active Synce Devices in $ActiveSyncDeviceList.
.PARAMETER to
The email address the email report will go to
.PARAMETER from
The email address the email report will come from
.PARAMETER SmtpServer
The IP address or DNS name of the SMTP server that will be used to send the email report
.PARAMETER HourInterval
The interval in hours. Any mailbox that hasn't synced to the Exchnage server
.PARAMETER ExchangeConnectionUri
URI of Powershell Session on an Exchange 2010 server. Used if the PC running this script does not have the required PSsnapin loaded
.EXAMPLE
Get-InactiveActiveSyncDevices -to User@company.com -from ActiveSyncDeviceReport@Company.com -SmtpServer Mail.company.com -HourInterval 24
Send an email report of all Active Sync devices that haven't synced to the mail server in the past 24 hours to User@company.com from ActiveSyncDeviceReport@Company.com through the email server with the DNS name of Mail.company.com
.EXAMPLE
Get-InactiveActiveSyncDevices -to User@company.com -from ActiveSyncDeviceReport@Company.com -SmtpServer 10.10.50.100 -HourInterval 24
Send an email report of all Active Sync devices that haven't synced to the mail server in the past 24 hours to User@company.com from ActiveSyncDeviceReport@Company.com through the email server with the DNS name of Mail.company.com
.EXAMPLE
Get-InactiveActiveSyncDevices -to User@company.com -from ActiveSyncDeviceReport@Company.com -SmtpServer 10.10.50.100 -HourInterval 24 -ExchangeConnectionUri http://mail.company.com/PowerShell/
Send an email report of all Active Sync devices that haven't synced to the mail server in the past 24 hours to User@company.com from ActiveSyncDeviceReport@Company.com through the email server with the DNS name of Mail.company.com using the Exchange Connection Uri of http://mail.company.com/PowerShell/ in order to use implicit remoting to pull in the required PSsnapin
.NOTES
NAME: Get-InactiveActiveSyncDevices
AUTHOR: John Mello
AUTHOR WEBSITE: mellositmusings.com
LASTEDIT: 02/17/2013
KEYWORDS: Exchange 2010, Active Synce
.LINK
Latest version can be found at : 
http://gallery.technet.microsoft.com/scriptcenter/Get-Active-Sync-devices-9bfb5116

#Requires -Version 2.0 
#>

[cmdletbinding()]

Param (
    [Parameter(Mandatory=$True,HelpMessage="Enter a email address to send the report too")]
    [string]$to,

    [Parameter(Mandatory=$True,HelpMessage="Enter the email address the report should come from")]
    [string]$from,

    [Parameter(Mandatory=$True,HelpMessage="Enter the IP or DNS name of the mail server that will send the report")]
    [string]$SmtpServer,

    [Parameter(Mandatory=$True,HelpMessage="Enter the hour interval to check against (e.g. 24)")]
    [int]$HourInterval,
	
	$ExchangeConnectionUri = $NULL
)

Write-Verbose "Checking if implict remoting to an Exchnage 2010 server was specified"
if ($ExchangeConnectionUri -eq $NULL)
	{
		Write-Verbose "Checking for Microsoft.Exchange.Management.PowerShell.E2010 PSSnapin"
		if ( (Get-PSSnapin -Name Microsoft.Exchange.Management.PowerShell.E2010 -ErrorAction SilentlyContinue) -eq $NULL )
			{
				Write-Verbose "Microsoft.Exchange.Management.PowerShell.E2010 not installed, intalling now"
				Add-PSSnapin -Name Microsoft.Exchange.Management.PowerShell.E2010
			}
		Else
			{
				Write-Verbose "Microsoft.Exchange.Management.PowerShell.E2010 PSSnapin is installed"
			}
	}
Else
	{
		Write-Verbose "Creating Implict remoting to $ExchangeConnectionUri"
		$ExchangeImplictSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $ExchangeConnectionUri -Authentication Kerberos
		Write-Verbose "Importing session"
		Import-PSSession $ExchangeImplictSession
	}
	
Write-Verbose "Get all Mailboxes using Get-CASMailbox and filter by the HasActiveSyncDevicePartnership property but do not include CAS or Discovery Mailboxes"
$ActiveSyncMailboxes = Get-CASMailbox -ResultSize unlimited -Filter{(HasActiveSyncDevicePartnership -eq $true) -AND (name -notlike "cas_*") -AND (name -notlike "DiscoverysearchMailbox*")} 

Write-Verbose "Start Processing list"
$ActiveSyncDeviceList = $ActiveSyncMailboxes |

	ForEach-Object { 
		Write-Verbose 'Pull the active sync device/devices from the current mailbox in $ActiveSyncMailboxes'
		$CurrentDevice = Get-ActiveSyncDeviceStatistics –Mailbox $_.Identity
		$VerboseNameHold=$_.Name
		Write-Verbose "Use an IF statement to check if the Mailbox belonging to $VerboseNameHold has multiple Active Sync Devices"
		If ($CurrentDevice -is [Array])
			{	
				Write-Verbose "User $VerboseNameHold has multiple Active Sync devices"
				$Index = 0
				Write-Verbose "Active sync device index = $Index"
				$VerboseTotalDeviceHold = $CurrentDevice.count
				$VerboseIndexHold = $Index + 1
				ForEach($Device in $CurrentDevice)
				{
					Write-Verbose "Current mailbox belonging to $VerboseNameHold has multiple devices currently on device # $VerboseIndexHold of $VerboseTotalDeviceHold"
					Write-Verbose "Putting Active Device Statistics into a hash table"
					$UserActiveSyncStats = @{
						Name=$_.Name
						DeviceType=$CurrentDevice[$index].DeviceType
						DeviceUserAgent=$CurrentDevice[$index].DeviceUserAgent
						DeviceID=$CurrentDevice[$index].DeviceID
						LastSyncAttemptTime=$CurrentDevice[$index].LastSyncAttemptTime
						LastSuccessSync=$CurrentDevice[$index].LastSuccessSync
					}
					
					Write-Verbose 'Creating a new Object using the $UserActiveSyncStats hashtable to create the properties, this will become an array entry in $ActiveSyncDeviceList'
					New-Object -TypeName PSObject -Property $UserActiveSyncStats
					$index++
					$VerboseIndexHold++
					Write-Verbose "Active Sync Device index incremented to $index"
				}
			}
		Else
			{
				Write-Verbose "Current mailbox beloning to $VerboseNameHold does not have multiple devices"
				Write-Verbose "Putting Active Device Statistics into a hash table"
				$UserActiveSyncStats = @{
					Name=$_.Name
					DeviceType=$CurrentDevice.DeviceType
					DeviceUserAgent=$CurrentDevice.DeviceUserAgent
					DeviceID=$CurrentDevice.DeviceID
					LastSyncAttemptTime=$CurrentDevice.LastSyncAttemptTime
					LastSuccessSync=$CurrentDevice.LastSuccessSync
				}
					Write-Verbose 'Creating a new Object using the $UserActiveSyncStats hashtable to create the properties, this will become an array entry in $ActiveSyncDeviceList'
					New-Object -TypeName PSObject -Property $UserActiveSyncStats
			}
	}

$CurrentDateandTime = Get-date
Write-Verbose "Saving Current date ($CurrentDateandTime) to a variable so that the same date is used for comparison to specified interval ($HoustsInterval)"

$date = $CurrentDateandTime.AddHours(-$HourInterval)
Write-Verbose "Subtracting ${HourInterval}hrs from todays date"

Write-Verbose "Finding devices that haven't synced since $date"
$MatchingActiveSyncDevices = $ActiveSyncDeviceList | Where-Object {$_.LastSuccessSync -le $date}

Write-Verbose 'Checking $MatchingActiveSyncDevices to see if it contains any devices that match tne criteria'
If ($MatchingActiveSyncDevices.count -gt 0) 
	{
		Write-Verbose '$MatchingActiveSyncDevices is not an empty array, devices that match the criteria have been found'

		Write-Verbose "Creating html header for email body"
		$HTMLHeader = "<Style>"
		$HTMLHeader = $HTMLHeader + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse}"
		$HTMLHeader = $HTMLHeader + "TH{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color: DarkGray}"
		$HTMLHeader = $HTMLHeader + "TD{border-width: 1px;padding: 0px;border-style: solid;border-color: black;background-color: PaleTurquoise}"
		$HTMLHeader = $HTMLHeader + "</Style>"
		
		Write-Verbose "Creating email body which incldues all devices that havent synced in the ${HourInterval}hrs"
		$body = $MatchingActiveSyncDevices | 
			sort LastSuccessSync | 
			ConvertTo-html -head $HTMLHeader -Property Name,LastSuccessSync,DeviceType,DeviceUserAgent,DeviceID,LastSyncAttemptTime | 
			Out-String
	}
Else
	{
		Write-Verbose '$MatchingActiveSyncDevices is an empty array, no devices that match the criteria have been found'
		$body = "All Active Sync devices have synced with the Exchange Server within the past ${HourInterval}hrs"
	}

Write-Verbose "Creating Email Subject"
$Subject = "Active Sync device report for " 
$Subject += $CurrentDateandTime.ToShortDateString()
$Subject += " : "
$Subject += $MatchingActiveSyncDevices.count
$Subject += " devices haven't synced in the past ${HourInterval}hrs since "
$Subject += $CurrentDateandTime.ToShortTimeString()
$Subject += " today"
		
Write-Verbose "Sending email from $from to $to via the following email server : $SmtpServer"
Send-MailMessage -to $to -Subject $Subject -From $from -SmtpServer $SmtpServer -Body $Body -BodyAsHtml
