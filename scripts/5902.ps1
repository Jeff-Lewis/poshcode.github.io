function RunSendEmail
{
	$date = Get-Date -Format F
    Send-MailMessage -To "HelpDesk <helpdesk@company.com>" -cc "IT Tech #1 <ittech@company.com>" -From "Server Service Monitor <no-reply-services@company.com>" -Subject "[SERVER.company.com] Service Failure(s)" -Body "Report generated on: $date
    
    $NewBody" -SmtpServer EMAILSERVER
}

#Filters the types of services you want to check.
Get-WmiObject Win32_Service | Where-Object {$_.Name -like '*Backup*' -and $_.StartMode -eq 'Auto' -and $_.State -eq 'Stopped'} | Select-Object Name | export-csv C:\temp\services.csv -NoTypeInformation
Get-WmiObject Win32_Service | Where-Object {$_.Name -like '*DLO*' -and $_.StartMode -eq 'Auto' -and $_.State -eq 'Stopped'} | Select-Object Name | export-csv C:\temp\services.csv -NoTypeInformation -Append
Get-WmiObject Win32_Service | Where-Object {$_.Name -like '*BKUPEXEC*' -and $_.StartMode -eq 'Auto' -and $_.State -eq 'Stopped'} | Select-Object Name | export-csv C:\temp\services.csv -NoTypeInformation -Append

#Logic. If the file is not empty then there are failures.
$NewBody = "The following list are services found that are listed as to be automatically running`f"
$NewBody = $NewBody + "and are currently stopped / not running.`f`f"
$NewBody = $NewBody + "Failed Services:`f"
$test = Import-CSV C:\temp\services.csv
if ($test -ne $NULL)
{
	Foreach ($line in $test)
	{
		$NewLine = $line.Name
		$NewLine = $NewLine + "`f"
		$NewBody = $NewBody + $NewLine

	}
	RunSendEmail
}
