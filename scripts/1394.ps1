#####################################################################
# Get-CertificationAuthority.ps1
# Version 1.0
#
# Retrieves all Enterprise Certification Authorities in cuurent AD forest
#
# Vadims Podans (c) 2009
# http://www.sysadmins.lv/
####################################################################

function Get-CertificationAuthority ([string]$CAName) {
	$domain = ([System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()).Name
	$domain = "DC=" + $domain -replace '\.', ", DC="
	$CA = [ADSI]"LDAP://CN=Enrollment Services, CN=Public Key Services, CN=Services, CN=Configuration, $domain"
	$CAs = $CA.psBase.Children | %{
		$current = "" | Select CAName, Computer
		$current.CAName = $_ | %{$_.Name}
		$current.Computer = $_ | %{$_.DNSHostName}
		$current
	}
	if ($CAName) {$CAs = @($CAs | ?{$_.CAName -eq $CAName})}
	if ($CAs.Count -eq 0) {throw "Sorry, here is no CA that match your search"}
	$CAs
}
