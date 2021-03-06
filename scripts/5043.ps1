<#
	.AUTHOR
		Chris Seiter
		4-2-14
		
	.SYNOPSIS
		Script that will check Windows System Restore status.
	
	.DESCRIPTION
		This script will connect to each computer listed and use WMI to check the
		status of the Windows System Restore.  If it is on, it will list all the
		current restore points that are available.  The input can be range from a
		single computer or a text file containing a list of computers.  The output
		is all objects so they can be piped to format how you wish.  Each computer
		is contacted in sequence.
		
	.PARAMETER TargetPath
		This is where the list of computers is gotten from. "TargetPath", "target", "computer"
		are all acceptable aliases.
		
	.EXAMPLE
		System_Restore_Settings.ps1
		This will list the system restore settings on the local machine and output them to the screen.
		
	.EXAMPLE
		System_Restore_Settings.ps1 | Out-File C:\reports\System_Restore.txt
		This will list the local machine's system restore settings and save them to a text file.
		
	.EXAMPLE
		System_Restore_Settings.ps1 -t scanbox
		This will list scanbox's system restore settings and output it to the screen.
		
	.EXAMPLE
		System_Restore_Settings.ps1 -t scanbox,terminal,exchange
		This will list scanbox, terminal, and exchange system restore settings.
		
	.EXAMPLE
		System_Restore_Settings.ps1 -t (Get-Content C:\reports\comp_list.txt)
		This will list each computer in the comp_list.txt file and their respective system restore settings.
		
	.NOTES
		Maybe the next version will have better error handling and run searches parallel.
	
#>

[CmdletBinding()]
Param(
	#Input file or computer name
	[Parameter(Mandatory=$False)]
	[Alias("target","computer")]
	[array]$TargetPath=[Environment]::MachineName,
	#username for remoting
	[Parameter(Mandatory=$true, HelpMessage="Use domain\username format.")]
	[string]$username,
	#password for remoting
	[Parameter(Mandatory=$true)]
	[SecureString]$password
)

Clear-Variable RP*
$RPStatus = @()
$RPCount = $TargetPath.Count

$RPCred = New-Object -TypeName system.Management.Automation.Pscredential -ArgumentList $username,$password

ForEach($Target in $TargetPath)
{
	$RPIndCount++
	$RPPercentage = "{0:P0}" -f ($RPIndCount/$RPCount)
	Write-Progress -Activity "Retrieving restore point settings" -Status "Parsing $Target" -CurrentOperation "$RPIndCount of $RPCount, $RPPercentage complete." -PercentComplete (($RPIndCount/$RPCount)*100)
	Try
	{
		$RPEnabled = Get-WmiObject -computername $Target -Namespace root\DEFAULT -Class SystemRestoreConfig -Credential $RPCred -ErrorAction Stop
		$RPDetails = Get-WmiObject -ComputerName $Target -Namespace root\DEFAULT -Class SystemRestore -Credential $RPCred -ErrorAction Stop
		ForEach($RestorePoint in $RPDetails)
		{
			$RPStatus += New-Object PSObject -Property @{
				"Computer"=$Target
				"Enabled"=$RPEnabled.RPSessionInterval
				"Created"=$RestorePoint.CreationTime
				"Description"=$RestorePoint.Description
				"Number"=$RestorePoint.SequenceNumber
			}
		}
	}
	Catch
	{
		$RPEnabled = Get-WmiObject -computername $Target -Namespace root\DEFAULT -Class SystemRestoreConfig
		$RPDetails = Get-WmiObject -ComputerName $Target -Namespace root\DEFAULT -Class SystemRestore
		ForEach($RestorePoint in $RPDetails)
		{
			$RPStatus += New-Object PSObject -Property @{
				"Computer"=$Target
				"Enabled"=$RPEnabled.RPSessionInterval
				"Created"=$RestorePoint.CreationTime
				"Description"=$RestorePoint.Description
				"Number"=$RestorePoint.SequenceNumber
			}
		}
	}
}

$RPStatus
