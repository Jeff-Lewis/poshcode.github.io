# Function to set current path as location of script ( Credit: blogs.msdn.com/powershell/archive/2007/06/19/get-scriptdirectory.aspx )
	function Get-ScriptDirectory
	{
	$Invocation = (Get-Variable MyInvocation -Scope 1).Value
	Split-Path $Invocation.MyCommand.Path
	}

	$scriptdir = Get-ScriptDirectory
	Set-Location $scriptdir
		
# Connect to Office365
	Set-ExecutionPolicy RemoteSigned
	$cred = Get-Credential
	$s = New-PSSession -ConfigurationName Microsoft.Exchange –ConnectionUri https://ps.outlook.com/powershell -Credential $cred -Authentication Basic –AllowRedirection
	$importresults = Import-PSSession $s
	Connect-MsolService -Credential $cred

# Fetch list of O365 Users
	$O365fetch = Get-Mailbox

# Blank array for results output
	$O365report=@()

# Create custom object to merge properties from get-mailbox and get-mailboxstatistics then add merged object to $O365report array
	$O365fetch | ForEach {
	
		$MBXstats = $_ | Get-MailboxStatistics
		
		Write-Progress -Activity "Getting your results!" -Status $_.PrimarySmtpAddress
		
		$O365user = [PSCustomObject]@{
	
			"DisplayName" = $MBXstats.DisplayName
			"PrimarySmtpAddress " = $_.PrimarySmtpAddress 
			"MBXtype" = $_.RecipientTypeDetails
			"LastLogonTime" = $MBXstats.LastLogonTime
			"StorageLimitStatus" = $MBXstats.StorageLimitStatus
			"TotalItemSize" = $MBXstats.TotalItemSize
			

		}

			$O365report += $O365user
	}
	
	
#Export report array to CSV
	$O365report | Export-Csv ".\O365 users report.csv" 
	
	

