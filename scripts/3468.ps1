function Get-NistNtpServer {
<#
	.SYNOPSIS
		Gets the list NIST NTP servers.

	.DESCRIPTION
		The Get-NistNtpServer function retrieves the list of NIST NTP server names, IP addresses, locations, and status.

	.EXAMPLE
		Get-NistNtpServer
		Returns the list of NIST NTP servers.

	.INPUTS
		None

	.OUTPUTS
		PSObject

	.NOTES
		Name: Get-NistNtpServer
		Author: Rich Kusak
		Created: 2011-12-31
		LastEdit: 2012-06-18 18:31
		Version: 1.1.0.0

	.LINK
		http://tf.nist.gov/tf-cgi/servers.cgi

#>

	[CmdletBinding()]
	param ()
	
	begin {
	
		$uri = 'http://tf.nist.gov/tf-cgi/servers.cgi'
		$webClient = New-Object -TypeName System.Net.WebClient
		$regex = '(td align = "center">.*)|(;">.*)'

	} # begin
	
	end {
	
		try {
			$webpage = $webClient.DownloadString($uri)
		} catch {
			throw $_
		}
		
		$list = ([regex]::Matches($webpage, $regex) | Select-Object -ExpandProperty Value) -replace '.*>' | Where-Object {
			 $_ -notlike $null
		}
		
		for ($i = 0 ; $i -lt $list.Count ; $i += 4) {
			New-Object -TypeName PSObject -Property @{
				'Name' = $list[(0 + $i)]
				'IPAddress' = $list[(1 + $i)]
				'Location' = $list[(2 + $i)]
				'Status' = $list[(3 + $i)]
		
			} | Select-Object -Property 'Name','IPAddress','Location','Status'
		
		} # for
	} # end
} # function Get-NistNtpServer

