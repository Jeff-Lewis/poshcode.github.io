###Variable to be changed
##Server Setup
@@###Variable to be changed
@@##Server Setup
@@$startDate=(get-date).addDays(-1) ##-1 equates to previous date
@@$endDate=(get-date) ##Current Date
@@$Server = "HC900WOC"

##Emails setup
@@$smtpserver = "HC900WE2.blah.com"
@@$smtpfrom = "Email@someone.com" ##From email
@@$smtpto = "Email@someone"  ##To email
@@$messagesubject = "Logon/Logoff Events for $server for Last 24hours" #email subject
###End variable to be changed 
 
# Store each event from the Security Log with the specificed dates and computer in an array $flog = failure logins $slog = Successful logins
#Searches for FailureAudit entry type
$flog = Get-Eventlog -LogName Security -ComputerName $server | where-object {$_.EntryType -eq 'failureAudit' -and $_.TimeGenerated -gt $startDate -and $_.TimeGenerated -lt $endDate}
#searches for EventID 528
$slog = Get-eventlog -LogName Security -ComputerName $server | Where-Object {$_.EventID -eq "528" -and $_.TimeGenerated -gt $startDate -and $_.TimeGenerated -lt $endDate}

##for testing to grab the newest 5 events
#$flog = Get-Eventlog -LogName Security -ComputerName $server -EntryType FailureAudit -newest 5
#$slog = Get-Eventlog -LogName Security -ComputerName $server -InstanceId 528 -newest 5
 
#Loop through each security event
[string]$messagebodyf = ""
[string]$messagebodys = ""
     foreach ($i in $flog){ 
        $table = @("Date: "," - User: ", " - Caller Domain: ") 
        $time = $table[0] + $i.TimeGenerated 
        $user = $table[1] + $i.ReplacementStrings[0]
	    $domain = $table[2] + $i.ReplacementStrings[1]
        $break = "`n`n"
        $messagebodyf = $messagebodyf + $time, $user + $domain + "`r`n"
        ##Possible future change to add results to log file.
		##add-content C:\temp\results.txt $time, $status, $user, $break
        }
    foreach ($s in $slog){ 
        $time = $table[0] + $s.TimeGenerated 
        $user = $table[1] + $s.ReplacementStrings[0]
		$domain = $table[2] + $s.ReplacementStrings[1]
        $break = "`n`n"
        $messagebodyS = $messagebodys + $time, $user + $domain + "`r`n"
		##Possible future change to add results to log file.
		##add-content C:\temp\results.txt $time, $status, $user, $break
        }
		
		##Begin send email portion
        $smtp = New-Object Net.Mail.SmtpClient($smtpServer)
        $messagebody = "Failed Logins: `n" + $messagebodyF + $break + "Successful Logins: `n" + $messagebodyS
        $smtp.Send($smtpFrom,$smtpTo,$messagesubject,$messagebody)$startDate=(get-date).addDays(-1) ##-1 equates to previous date
$endDate=(get-date) ##Current Date
$Server = "HC900WOC"

##Emails setup
$smtpserver = "HC900WE2.hteeter.ht"
$smtpfrom = "revans@harristeeter.com" ##From email
$smtpto = "revans@harristeeter.com"  ##To email
$messagesubject = "Logon/Logoff Events for $server for Last 24hours" #email subject
###End variable to be changed 
 
# Store each event from the Security Log with the specificed dates and computer in an array $flog = failure logins $slog = Successful logins
#Searches for FailureAudit entry type
$flog = Get-Eventlog -LogName Security -ComputerName $server | where-object {$_.EntryType -eq 'failureAudit' -and $_.TimeGenerated -gt $startDate -and $_.TimeGenerated -lt $endDate}
#searches for EventID 528
$slog = Get-eventlog -LogName Security -ComputerName $server | Where-Object {$_.EventID -eq "528" -and $_.TimeGenerated -gt $startDate -and $_.TimeGenerated -lt $endDate}

##for testing to grab the newest 5 events
#$flog = Get-Eventlog -LogName Security -ComputerName $server -EntryType FailureAudit -newest 5
#$slog = Get-Eventlog -LogName Security -ComputerName $server -InstanceId 528 -newest 5
 
#Loop through each security event
[string]$messagebodyf = ""
[string]$messagebodys = ""
     foreach ($i in $flog){ 
        $table = @("Date: "," - User: ", " - Caller Domain: ") 
        $time = $table[0] + $i.TimeGenerated 
        $user = $table[1] + $i.ReplacementStrings[0]
	    $domain = $table[2] + $i.ReplacementStrings[1]
        $break = "`n`n"
        $messagebodyf = $messagebodyf + $time, $user + $domain + "`r`n"
        ##Possible future change to add results to log file.
		##add-content C:\temp\results.txt $time, $status, $user, $break
        }
    foreach ($s in $slog){ 
        $time = $table[0] + $s.TimeGenerated 
        $user = $table[1] + $s.ReplacementStrings[0]
		$domain = $table[2] + $s.ReplacementStrings[1]
        $break = "`n`n"
        $messagebodyS = $messagebodys + $time, $user + $domain + "`r`n"
		##Possible future change to add results to log file.
		##add-content C:\temp\results.txt $time, $status, $user, $break
        }
		
		##Begin send email portion
        $smtp = New-Object Net.Mail.SmtpClient($smtpServer)
        $messagebody = "Failed Logins: `n" + $messagebodyF + $break + "Successful Logins: `n" + $messagebodyS
        $smtp.Send($smtpFrom,$smtpTo,$messagesubject,$messagebody)
