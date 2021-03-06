#Author: Ant B 2012
#Purpose: Batch feed recipients to MailChimp

# Check for ActiveDirectory Module and load if it isn't already.
if ( (Get-Module -Name ActiveDirectory -ErrorAction SilentlyContinue) -eq $null )
{
    Import-Module ActiveDirectory
}

$ie = new-object -com "InternetExplorer.Application"

# Vars for building the URL
@@$apikey = "<Your API Key>"
@@$listid = "<Your list ID>"
$URL = "https://us4.api.mailchimp.com/1.3/?output=xml&method=listBatchSubscribe&apikey=$apikey"
$URLOpts = "&id=$($listid)&double_optin=False&Update_existing=True"
$Header = "surname","givenanme","mail"

# Get members of the group
@@$DGMembers = Get-AdGroupMember -Identity "<Full path to AD Group>" | ForEach {Get-ADUser $_.samaccountname -Properties mail} | Select GivenName, Surname, mail

# Copy the array contents to a CSV for comparison on the next run, we'll use it to look for removals
if (test-path "submitted.csv") {Clear-Content submitted.csv}
$DGMembers | select mail | export-csv submitted.csv

# Check for the CSV created above and dump it to an array for comparison
if (test-path "submitted.csv") {$list = Import-CSV -delimiter "," -Path submitted.csv -Header $Header}
$Removals = compare-object $DGMembers $list | Where {$_.SideIndicator -eq "=>"}

# Loop through the array of group members and submit to the MailChimp API
ForEach ($ObjItem in $DGMembers)
{
$batch = "&batch[0][EMAIL]=$($ObjItem.mail)&batch[0][FNAME]=$($ObjItem.givenname)&batch[0][LNAME]=$($ObjItem.surname)"
$MailOpts = "&batch[0][EMAIL_TYPE]html"
$FURL = $URL + $batch + $MailOpts + $URLOpts
Write-Host $FURL
$ie.navigate($FURL)
Start-Sleep -MilliSeconds 300
}

