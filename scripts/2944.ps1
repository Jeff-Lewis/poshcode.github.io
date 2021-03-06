function Get-MacAddressOui {
<#
	.SYNOPSIS
		Gets a MAC address OUI (Organizationally Unique Identifier).

	.DESCRIPTION
		The Get-MacAddressOui function retrieves the MAC address OUI reference list maintained by the IEEE standards website and
		returns the name of the company to which the MAC address OUI is assigned.

	.PARAMETER MacAddress
		Specifies the MAC address for which the OUI should be retrieved.

	.EXAMPLE
		Get-MacAddressOui 00:02:B3:FF:FF:FF
		Returns the MAC address OUI and the company assigned that idenifier.

	.INPUTS
		System.String

	.OUTPUTS
		PSObject

	.NOTES
		Name: Get-MacAddressOui
		Author: Rich Kusak (rkusak@hotmail.com)
		Created: 2011-09-01
		LastEdit: 2011-09-02 12:51
		Version: 1.0.0.0

	.LINK
		http://standards.ieee.org/develop/regauth/oui/oui.txt

	.LINK
		about_regular_expressions

#>

	[CmdletBinding()]
	param (
		[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
		[ValidateScript({
			$patterns = @(
				'^[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}$'
				'^[0-9a-f]{2}-[0-9a-f]{2}-[0-9a-f]{2}-[0-9a-f]{2}-[0-9a-f]{2}-[0-9a-f]{2}$'
				'^[0-9a-f]{4}\.[0-9a-f]{4}\.[0-9a-f]{4}$'
				'^[0-9a-f]{12}$'
			)
			if ($_ -match ($patterns -join '|')) {$true} else {
				throw "The argument '$_' does not match a valid MAC address format."
			}
		})]
		[string]$MacAddress
	)
	
	begin {
	
		$uri = 'http://standards.ieee.org/develop/regauth/oui/oui.txt'
		$webClient = New-Object System.Net.WebClient
		$ouiReference = $webClient.DownloadString($uri)
		$properties = 'MacAddress', 'OUI', 'Company'

	} # begin
	
	process {
	
		$oui = ($MacAddress -replace '\W').Remove(6)
		
		New-Object PSObject -Property @{
			'MacAddress' = $MacAddress
			'OUI' = $oui
			'Company' = [regex]::Match($ouiReference, "($oui)\s*\(base 16\)\s*(.+)").Groups[2].Value
		} | Select $properties
	
	} # process
} # function Get-MacAddressOui

