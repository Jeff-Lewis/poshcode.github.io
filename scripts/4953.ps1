# Get-WSManCredSSPConfiguration.ps1
# Compile a WSManCredSSP configuration object for the local or remote computer
# Inspired by http://www.ravichaganti.com/blog/?p=1902
# http://blog.victorvogelpoel.nl/2014/03/03/powershell-get-wsmancredsspconfiguration-getting-credssp-configuration-for-local-or-remote-computers/
#
# Disclaimer
# This script is provided AS IS without warranty of any kind. I disclaim all implied
# warranties including, without limitation, any implied warranties of merchantability
# or of fitness for a particular purpose. The entire risk arising out of the use or 
# performance of the sample scripts and documentation remains with you. In no event 
# shall I be liable for any damages whatsoever (including, without limitation, damages 
# for loss of business profits, business interruption, loss of business information, 
# or other pecuniary loss) arising out of the use of or inability to use the script or 
# documentation.
#
# Oct 2013
# If this works, Ravikanth Chaganti and Victor Vogelpoel <victor.vogelpoel@macaw.nl> wrote this.
# If it doesn't, I don't know who wrote this.

#requires -version 3
Set-PSDebug -Strict
Set-StrictMode -Version Latest


# NOTE: if using credentials, make sure to use DOMAIN\ACCOUNT format for username!
function Get-WSManCredSSPConfiguration
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$false, position=0, ValueFromPipeLine=$true, ValueFromPipeLineByPropertyName=$true, HelpMessage="Computers to get the CredSSP configuration for")]
		[String[]]$computerName = "localhost",

		[Parameter(Mandatory=$false, Position=1, ValueFromPipelineByPropertyName=$true, HelpMessage="Credential to connect to the computers with")]
		[Management.Automation.PSCredential]$Credential
	)
	
	begin
	{
		function Test-ElevatedProcess
		{
			return (New-Object Security.Principal.WindowsPrincipal -ArgumentList ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole( [Security.Principal.WindowsBuiltInRole]::Administrator )
		}
		
		function Resolve-FQDNHostName
		{
			[CmdletBinding()]
			param
			(
				[Parameter(Mandatory=$false, position=0, ValueFromPipeLine=$true, ValueFromPipeLineByPropertyName=$true, HelpMessage="TODO")]
				[Alias('CN','__SERVER', 'Server', 'Hostname')]
				[String[]]$ComputerName = "localhost"
			)
			
			process
			{
				foreach ($comp in $ComputerName)
				{
					try
					{
						if ($comp -eq ".") { $comp = "localhost" }
				
						Write-Output ([System.Net.Dns]::GetHostByName($comp).HostName)
					}
					catch
					{
						throw "ERROR while resolving server `"$comp`": $($_.Exception.Message)"
					}
				}
			}
		}
	
		if (!(Test-ElevatedProcess))
		{
			throw "ERROR: WSManCredSSPConfiguration can only be used in an elevated PowerShell session."
		}
		
		$localComputer 		= Resolve-FQDNHostName
	}

	process
	{
		foreach ($computer in $computerName)
		{
			$computer 		= Resolve-FQDNHostName -ComputerName $computer
			$credsspConfig 	= $null
			
			if ($computer -eq $localComputer)
			{
				$credsspConfig = New-Object -TypeName PSObject
				$credsspConfig | Add-Member -MemberType NoteProperty -Name "computerName"			-Value $computer
				$credsspConfig | Add-Member -MemberType NoteProperty -Name "IsServer" 				-Value $false
				$credsspConfig | Add-Member -MemberType NoteProperty -Name "IsClient" 				-Value $false
				$credsspConfig | Add-Member -MemberType NoteProperty -Name "AllowFreshCredentials"	-Value "NA"
				$credsspConfig | Add-Member -MemberType NoteProperty -Name "ClientDelegateComputer"	-Value ""
				
				if ($Credential)
				{
					$wsmanTest = Test-WSMan -Credential $Credential -ErrorAction SilentlyContinue
				}
				else
				{
					$wsmanTest = Test-WSMan -ErrorAction SilentlyContinue
				}
						
				if ($wsmanTest)
				{
					$isServer = ((Get-Item WSMan:\LocalHost\Service\Auth\CredSSP).Value -eq "true")
					$isClient = ((Get-Item WSMan:\LocalHost\Client\Auth\CredSSP).Value -eq "true")
				
					$credsspConfig.IsServer = $isServer
					$credsspConfig.IsClient = $isClient
					
					if ($isClient -and (Test-Path HKLM:\software\policies\microsoft\windows\CredentialsDelegation\AllowFreshCredentials))
					{
						$credsspConfig.AllowFreshCredentials = (Get-ItemProperty HKLM:\software\policies\microsoft\windows\CredentialsDelegation).AllowFreshCredentials
						
						# Extract registry values for 1,2,3,... from HKLM:\software\policies\microsoft\windows\CredentialsDelegation\AllowFreshCredentials, which are the delegate computers from "Enable-WSMANCredSSP -role client -delegatecomputer"
						$delegateComputers = @((Get-ItemProperty HKLM:\software\policies\microsoft\windows\CredentialsDelegation\AllowFreshCredentials).psobject.Properties | where { $_.Name -match "\d+"  } | select -expand value | foreach { if ($_ -like "wsman/*") { $_.substring(6) } else { $_ } })
						
						# Store delegatecomputers in the custom object 						
						$credsspConfig.ClientDelegateComputer = $delegateComputers
					}
				}
				else
				{
					throw "Could not connect to WSMAN; is the WinRM service running on `"$computer`"? Run `"WinRM quickconfig -force`"!"
				}
			}
			else
			{
				if (Test-WSMan -ComputerName $computer -ErrorAction SilentlyContinue)   # Note: does NOT take -Credential, otherwise error "flagged with no authentication"
				{
					$credsspConfig = New-Object -TypeName PSObject
					$credsspConfig | Add-Member -MemberType NoteProperty -Name "computerName" 			-Value $computer
					$credsspConfig | Add-Member -MemberType NoteProperty -Name "IsServer" 				-Value $false
					$credsspConfig | Add-Member -MemberType NoteProperty -Name "IsClient" 				-Value $false
					$credsspConfig | Add-Member -MemberType NoteProperty -Name "AllowFreshCredentials" 	-Value "NA"
					$credsspConfig | Add-Member -MemberType NoteProperty -Name "ClientDelegateComputer"	-Value ""
					
					try
					{
						$WSManConnected = $false
					
						if ($Credential)
						{
							Connect-WSMan -ComputerName $computer -Credential $Credential -ErrorAction SilentlyContinue
						}
						else
						{
							Connect-WSMan -ComputerName $computer -ErrorAction SilentlyContinue
						}
					
						$WSManConnected = $true
						$isServer 		= ((Get-Item "WSMan:\$($computer)\Service\Auth\CredSSP").Value -eq "true")
						$isClient		= ((Get-Item "WSMan:\$($computer)\Client\Auth\CredSSP").Value -eq "true")

						$credsspConfig.IsServer = $isServer
						$credsspConfig.IsClient = $isClient
												
						#Write-Verbose "WSMan:\$($computer)\Client\Auth\CredSSP"
						if ($isClient)
						{
							# Start collecting the CredSSP client role configuration on the remote computer by querying the registry remotely (using WMI)
							
							$reg = $null
							
							try
							{
								if ($Credential)
								{
									# Get the WMI registry provider using credentials
									$reg = Get-WmiObject -List -Namespace root\default -ComputerName $computer -Credential $Credential | Where-Object {$_.Name -eq "StdRegProv"}
								}
								else
								{
									# Get the WMI registry provider using current credentials
									$reg = Get-WmiObject -List -Namespace root\default -ComputerName $computer | Where-Object {$_.Name -eq "StdRegProv"}
								}
								
								$HKLM					= 2147483650
								$allowFreshCredentials 	= $reg.GetDWORDValue($HKLM, "SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation", "AllowFreshCredentials").uValue
								if ($allowFreshCredentials -ne $null)
								{
									$credsspConfig.AllowFreshCredentials = $allowFreshCredentials
								
									# Query the delegate computers from the registry
									$delegateComputers = $reg.EnumValues($HKLM, "SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials").sNames | foreach {
															$delegateComputer = $reg.GetStringValue($HKLM, "SOFTWARE\Policies\Microsoft\Windows\CredentialsDelegation\AllowFreshCredentials", $_).sValue
															if ($delegateComputer -like "wsman/*") { $delegateComputer.substring(6) } else { $delegateComputer } 
														}
														
									# Add the found delegate computers to the configuration object!
									$credsspConfig.ClientDelegateComputer = $delegateComputers
														
								}
							}
							catch
							{
								throw "ERROR while reading remote registry on computer `"$computer`": $($_.Exception.Message)"

								$credsspConfig.AllowFreshCredentials = "ERROR"
							}
						}
					}
					catch 
					{
						$exMessage  = $_.Exception.Message
						$advise 	= ""

						if ($exMessage -like "Access is denied.*" -or $exMessage -like "The user name or password is incorrect*")
						{
							$advise = "Please supply proper credentials."
						}

						throw "ERROR while connecting to WSMAN on $computer or gathering CredSSP information: `"$exMessage`". $advise"
					}
					finally
					{
						if ($WSManConnected)
						{
							Disconnect-WSMan -ComputerName $computer
						}
					}
				}
				else
				{
					throw "ERROR: could not connect to WSMAN on `"$computer`"? Is WinRM service running? Run `"WinRM quickconfig -force`" on this computer!"
				}
			}
			
			Write-Output $credsspConfig
		}
	}
	
<#
.SYNOPSIS
Retrieves the CredSSP configuration for the local or remote computers. 
   
.DESCRIPTION
Get-WSManCredSSPConfiguration retrieves CredSSP configuration for one
or more computers and returns the configuration as a custom PS object:

  computerName              computer for this configuration
  IsServer                  Has the computer the CredSSP server role?
  IsClient                  Has the computer the CredSSP client role?
  AllowFreshCredentials     Value of the Allow Fresh Credentials
  ClientDelegateComputer    If client role enabled, this holds the array 
                            of computers where the computer can delegate
							credentials to.

Get-WSManCredSSPConfiguration connects to other computers with either 
current credentials or the specified credentials. These credentials must 
have administrative privileges. WSMan must have been enabled on the
computers in order to connect.
   
.PARAMETER ComputerName
When specified, one or more computers to get the CredSSP configuration for.
(Get-WSManCredSSPConfiguration connects to other computers with either 
current credentials or the specified credentials.)
Wen not specified, the CredSSP configuration for the current computer
is returned.

.PARAMETER Credential
When specified, this is the credential that is used to connect to other computers.

.EXAMPLE
PS> Get-WSManCredSSPConfiguration

Gets the CredSSP configuration for the local computer, for example:

computerName           : laptop01.domain.com
IsServer               : False
IsClient               : True
AllowFreshCredentials  : 1
ClientDelegateComputer : {server01.domain.com, server02.domain.com}

.EXAMPLE
PS> Get-WSManCredSSPConfiguration -computername server01.domain.com 

Connects to server01.domain.com with current credentials and gets the
CredSSP configuration:

computerName           : server01.domain.com
IsServer               : True
IsClient               : false
AllowFreshCredentials  : NA
ClientDelegateComputer : 

.EXAMPLE
PS> Get-WSManCredSSPConfiguration -computername server01.domain.com -credential $admincred

Connects to server01.domain.com with the credentials $admincred and gets the
CredSSP configuration:

computerName           : server01.domain.com
IsServer               : True
IsClient               : false
AllowFreshCredentials  : NA
ClientDelegateComputer : 

.EXAMPLE
PS> Get-WSManCredSSPConfiguration | select -expand ClientDelegateComputer

Gets the CredSSP configuration for the local computer and returns the
array of computers for which the local computer may delegate credentials:

server01.domain.com
server02.domain.com


.NOTES
Author:      Victor Vogelpoel
Date:        Oct 2013
Inspired by: http://www.ravichaganti.com/blog/?p=1902

IMPORTANT: Get-WSManCredSSPConfiguration must be invoked in an elevated
PowerShell session. Start PowerShell session with "Run-as administrator"

.LINK
Get-WSManCredSSP

See Victor's blogpost about Get-WSManCredSSPConfiguration:
http://blog.victorvogelpoel.nl/2014/03/03/powershell-get-wsmancredsspconfiguration-getting-credssp-configuration-for-local-or-remote-computers/

Scripting guys about CredSSP:
http://blogs.technet.com/b/heyscriptingguy/archive/2012/11/14/enable-powershell-quot-second-hop-quot-functionality-with-credssp.aspx

#>
}


# Get-WSManCredSSPConfiguration -computerName server01.domain.com -Credential (Get-Credential) -Verbose
# Get-WSManCredSSPConfiguration $env:COMPUTERNAME
# Get-WSManCredSSPConfiguration -Verbose


