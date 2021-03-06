#Get group membership for a list of security 
#groups and export to an XML for comparison 
#against baseline.
#

$script:WorkingDirectory = split-path $myinvocation.Mycommand.Definition -parent


Function Re-Baseline
{
#First, declare array and hashtable.
$securitygroups = @()
$table = @{}
#Import Security Group list from XML and add to "securitygroups" array.
$securitygroupsxml = [XML] (gc "$script:WorkingDirectory\sg.xml")
$securitygroups += $securitygroupsxml.objs.S
#Get membership for each group
foreach($securitygroup in $securitygroups){
$dom = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain() 
$root = [ADSI] "LDAP://$($dom.Name)"
$searcher = New-Object System.DirectoryServices.DirectorySearcher $root
$searcher.filter = "(&(objectCategory=group)(objectClass=group)(sAMAccountName=$securitygroup))" 
$group = $searcher.findone()

$table += @{"$securitygroup"= $group.properties.member}
}
#Export hashtable to XML.  So nice.
$table | export-clixml $script:WorkingDirectory\baseline.xml
}




#
#First, declare hashtable.
$comparetable = @{}

#Import Security Group list from XML and add to "securitygroups" array.
$securitygroupsxml = [XML] (gc "$script:WorkingDirectory\sg.xml")
$securitygroups = $securitygroupsxml.objs.S

#Get membership for each group and create a compare table.
foreach($securitygroup in $securitygroups){
	$dom = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
	$root = [ADSI] "LDAP://$($dom.Name)"
	$searcher = New-Object System.DirectoryServices.DirectorySearcher $root
	$searcher.filter = "(&(objectCategory=group)(objectClass=group)(sAMAccountName=$securitygroup))"
	$group = $searcher.findone()
	$comparetable += @{"$securitygroup"= $group.properties.member}
}

#Export hashtable to XML.  So nice.
$comparetable | export-clixml "$script:WorkingDirectory\compare.xml"

#Import baseline XML to hashtable.
$baselinetable = @{}
$baselinetable += import-clixml "$script:WorkingDirectory\baseline.xml"

#Import baseline XML to hashtable.
$comparetable = @{}
$comparetable += import-clixml "$script:WorkingDirectory\compare.xml"

#Compare respective Keys and Values for $comparetable against
#$baselinetable and get differences.
$passtoemailsubuser = @()
$passtoemailbody = @()
foreach($securitygroup in $securitygroups) {

	
		
		If($comparetable."$securitygroup" -eq $NULL)
		{
			If($baselinetable."$securitygroup" -eq $NULL)
			{
				(get-date).tostring() + " - Security Group $securitygroup is empty in the compare and the baseline" >> $script:WorkingDirectory\log.txt
			}
			Else
			{
			foreach($entry in $baselinetable."$securitygroup")
			{$passtoemailbody += "`r" + $entry + " " + "`r`r" + "***WAS REMOVED FROM***: " + "`r`r" + $securitygroup + "`r`r"}
			$passtoemailbody += "`r" + $securitygroup + " " + "`r`r" + "in AD contains no more objects" + "`r`r"
			(get-date).tostring() + " - $securitygroup in AD contains no more objects" >> $script:WorkingDirectory\log.txt
			}
		}
	
		Else
		{
		$baseline = @($baselinetable."$securitygroup")
		$compare = @($comparetable."$securitygroup")
		$results = Compare-Object $baseline $compare
		foreach($result in $results){
			if (($result.equals.isinstance -eq $true) -and ($result.sideindicator -eq "=>")) {$passtoemailbody += "`r" + $result.inputobject + " " + "`r`r" + "***WAS ADDED TO***: " + "`r`r" + $securitygroup + "`r`r"
            $user = $result.inputobject
            $searcher.filter = "(&(objectCategory=person)(objectClass=user)(distinguishedname=$user))"
            $user = $searcher.FindOne()
            $passtoemailsubuser += $user.properties.samaccountname
            $mod = $true
            }
			if (($result.equals.isinstance -eq $true) -and ($result.sideindicator -eq "<=")) {$passtoemailbody += "`r" + $result.inputobject + " " + "`r`r" + "***WAS REMOVED FROM***: " + "`r`r" + $securitygroup + "`r`r"
            $user = $result.inputobject
            $searcher.filter = "(&(objectCategory=person)(objectClass=user)(distinguishedname=$user))"
            $user = $searcher.FindOne()
            $passtoemailsubuser += $user.properties.samaccountname
            $mod = $true
            }}
}
}


if ($mod -eq $true) {
	$from = New-Object System.Net.Mail.MailAddress "from@address.com" 
	$to =   New-Object System.Net.Mail.MailAddress "to@address.com" 
	$message = new-object  System.Net.Mail.MailMessage $from, $to 
	$message.Subject = "The following accounts were involved in a security group modification: $passtoemailsubuser" 
	$message.Body = "Note the following security group modification information: `r`r $passtoemailbody"
	$server = "SMTPSERVERNAME" 
	$client = new-object system.net.mail.smtpclient $server
	$client.port = 125
	$client.Send($message)
	foreach($entry in $passtoemailbody)
	{(get-date).tostring() + " - " + $Entry >> $script:WorkingDirectory\Log.txt}
	(get-date).tostring() + " - Group Membership compare has been baselined" >> $script:WorkingDirectory\log.txt
	re-baseline	
	}
else { 
	$from = New-Object System.Net.Mail.MailAddress "from@address.com" 
	$to =   New-Object System.Net.Mail.MailAddress "to@address.com" 
	$message = new-object  System.Net.Mail.MailMessage $from, $to 
	$message.Subject = "No modifications to the audited security groups have been made." 
	$message.Body = "No modifications to the audited security groups have been made."
	$server = "SMTPSERVERNAME" 
	$client = new-object system.net.mail.smtpclient $server
	$client.port = 125
	$client.Send($message)
	"No Changes have been made"
	}



