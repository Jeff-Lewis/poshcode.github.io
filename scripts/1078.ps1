# The Get-HotFix function gets the quick-fix engineering (QFE) updates that have been applied to the local computer or to remote computers and filter those hotfixes named "file 1".
# There is Get-HotFix cmdlet in PowerShell V2. This is an attempt to bring similar functionality to V1.

function Get-HotFix {
	param (
	[string[]]$ComputerName = ".",
	[string]$Id = "",
	[string]$Description = "",
	$credential
	)

	if ($credential -is [String] ) {
		$credential = Get-Credential $credential
	}


	if ($id -ne "" -and $Description -eq "") {
		$id = $id.Replace("*","%");$filter = "hotfixid LIKE '$id'"
	}
	elseif ($id -eq "" -and $Description -ne "") {
		$Description = $Description.Replace("*","%");$filter = "description LIKE '$Description'"
	}
	elseif ($id -ne "" -and $Description -ne "") {
		Write-Host "WARNING: Use Id or Description parameter." -foregroundcolor yellow ;break
	}
	else {
		$filter = ""
	}

	if ($credential -eq $null) {
		$HotFixes = get-wmiobject Win32_QuickFixEngineering -computerName $ComputerName -filter $filter | where-object {$_.hotfixid -ne "file 1"}
	} else {
		$HotFixes = get-wmiobject Win32_QuickFixEngineering -computerName $ComputerName -filter $filter -credential $credential | where-object {$_.hotfixid -ne "file 1"}
	}

	$HotFixes
}

# Examples:
#
# C:\PS>get-hotfix
#
# C:\PS>get-hotfix -Id *929*
# 
# C:\PS>get-hotfix | format-table hotfixid,installedon,servicepackineffect,description -auto -wrap
# 
# C:\PS>get-hotfix | convertto-html -property hotfixid,description -title "Installed HotFixes" > c:\temp\hotfixes.html
# 
# C:\PS>get-hotfix -description Security* -computername Server01 -credential Server01\admin01
#
# C:\PS>get-hotfix -description Security* -computername Server01,Server02 | ft __server,desc*
# 
# C:\PS>$a = get-content servers.txt
#       $a | foreach { if (!(get-hotfix -id KB958644 -computername $_)) { add-content $_ -path Missing-KB958644.txt }}
