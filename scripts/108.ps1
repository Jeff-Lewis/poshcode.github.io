#â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”
# Func/Sub Name: Send-RTMTask
# Purpose: Sends a task to the Remember The Milk system via email.
# Arguments Supplied:
# Return Value:
# External Reference:
#â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”â€”
function Send-RTMTask
{
 param( [string]$TaskName=$(Throw "need TaskName"), 
        $Priority,
		$DueDate,
		$Repeat,
		$TaskEstimate,
		$Tags,
		$Location,
		$URL,
		[string]$TaskList,
		$Notes
	  )
 Begin
 { 
@@	# Some Constants
@@	$RTMEmailAddress = ""
@@	$FromEmailAddress = ""
@@	$SMTPServer = ""
	
	
	$MailClient = New-Object System.Net.Mail.SmtpClient($SMTPServer)
 }
 Process
 { 
 	$FromEmail = New-Object System.Net.Mail.MailAddress($FromEmailAddress )
	$ToEmail   = New-Object System.Net.Mail.MailAddress($RTMEmailAddress )
	$MailMessage = New-Object System.Net.Mail.MailMessage( $FromEmail, $ToEmail)
	$MailMessage.Subject = $TaskName
	
	$Body = ""
	if ( $Priority -ne $null )     { $Body += "P: $Priority`n" }
	if ( $DueDate -ne $null )      { $Body += "Due: $DueDate`n" }
	if ( $Repeat -ne $null )       { $Body += "Repeat: $Repeat`n" }
	if ( $TaskEstimate -ne $null ) { $Body += "EstimateP: $TaskEstimate`n" }
	if ( $Tags -ne $null )         { $Body += "Tags: $Tags`n" }
	if ( $Location -ne $null )     { $Body += "Location: $Location`n" }
	if ( $URL -ne $null )          { $Body += "URL: $URL`n" }
	if ( $TaskList -ne $null )     { $Body += "List: $TaskList`n" }
	if ( $Notes -ne $null )        { $Body += "--- `n $Notes" }
	$MailMessage.Body = $Body
	$MailClient.Send($MailMessage)
 
 }
 End
 { }
}

