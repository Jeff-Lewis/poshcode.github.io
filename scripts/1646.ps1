#####################################################################
# Test-Certificate.ps1
# Version 0.9
#
# Tests specified certificate for certificate chain and revocation
#
# Vadims Podans (c) 2009
# http://www.sysadmins.lv/
#####################################################################
#requires -Version 2.0

function Test-Certificate {
<#
.Synopsis
	Tests specified certificate for certificate chain and revocation
.Description
	Tests specified certificate for certificate chain and revocation status for each certificate in chain
	exluding Root certificates
.Parameter Certificate
	Specifies the certificate to test certificate chain. This parameter may accept
	X509Certificate, X509Certificate2 objects or physical file path. this paramter accept
	pipeline input
.Parameter Password
	Specifies PFX file password. Password must be passed as SecureString.
.Parameter CRLMode
	Sets revocation check mode. May contain on of the following values:
	
	Online - perform revocation check downloading CRL from CDP extension ignoring cached CRLs. Default value
	Offline - perform revocation check using cached CRLs if they are already downloaded
	NoCheck - specified certificate will not checked for revocation status (not recommended)
.Parameter CRLFlag
	Sets revocation flags for chain elements. May contain one of the following values:
	
	ExcludeRoot - perform revocation check for each certificate in chain exluding root. Default value
	EntireChain - perform revocation check for each certificate in chain including root. (not recommended)
	EndCertificateOnly - perform revocation check for specified certificate only.
.Parameter VerificationFlags
	Sets verification checks that will bypassed performed during certificate chaining engine
	check. You may specify one of the following values:
	
	NoFlag - No flags pertaining to verification are included (default).
	IgnoreNotTimeValid - Ignore certificates in the chain that are not valid either because they have expired or they
		are not yet	in effect when determining certificate validity.
	IgnoreCtlNotTimeValid - Ignore that the certificate trust list (CTL) is not valid, for reasons such as the CTL
		has expired, when determining certificate verification.
	IgnoreNotTimeNested - Ignore that the CA (certificate authority) certificate and the issued certificate have
		validity periods that are not nested when verifying the certificate. For example, the CA cert can be valid
		from January 1 to December 1 and the issued certificate from January 2 to December 2, which would mean the
		validity periods are not nested.
	IgnoreInvalidBasicConstraints - Ignore that the basic constraints are not valid when determining certificate
		verification.
	AllowUnknownCertificateAuthority - Ignore that the chain cannot be verified due to an unknown certificate
		authority (CA).
	IgnoreWrongUsage - Ignore that the certificate was not issued for the current use when determining
		certificate verification.
	IgnoreInvalidName - Ignore that the certificate has an invalid name when determining certificate verification.
	IgnoreInvalidPolicy - Ignore that the certificate has invalid policy when determining certificate verification.
	IgnoreEndRevocationUnknown - Ignore that the end certificate (the user certificate) revocation is unknown when
		determining	certificate verification.
	IgnoreCtlSignerRevocationUnknown - Ignore that the certificate trust list (CTL) signer revocation is unknown
		when determining certificate verification.
	IgnoreCertificateAuthorityRevocationUnknown - Ignore that the certificate authority revocation is unknown 
		when determining certificate verification.
	IgnoreRootRevocationUnknown - Ignore that the root revocation is unknown when determining certificate verification.
	AllFlags - All flags pertaining to verification are included.	
.Example
	Get-ChilItem cert:\CurrentUser\My | Test-Certificate -CRLMode "NoCheck"
	
	Will check certificate chain for each certificate in current user Personal container.
	Certificates will not checked for revocation status.
.Example
	Test-Certificate C:\Certs\certificate.cer -CRLFlag "EndCertificateOnly"
	
	Will check certificate chain for certificate that is located in C:\Certs and named
	as Certificate.cer and revocation checking will be performed for specified certificate only
.Outputs
	This script return general info about certificate chain status
#>
[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
		$Certificate,
		[System.Security.SecureString]$Password,
		[System.Security.Cryptography.X509Certificates.X509RevocationMode]$CRLMode = "Online",
		[System.Security.Cryptography.X509Certificates.X509RevocationFlag]$CRLFlag = "ExcludeRoot",
		[System.Security.Cryptography.X509Certificates.X509VerificationFlags]$VerificationFlags = "NoFlag"
	)
	
	begin {
		$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
		$chain = New-Object System.Security.Cryptography.X509Certificates.X509Chain
		$chain.ChainPolicy.RevocationFlag = $CRLFlag
		$chain.ChainPolicy.RevocationMode = $CRLMode
		$chain.ChainPolicy.VerificationFlags = $VerificationFlags
		function _getstatus_ ($status, $chain, $cert) {
			if ($status) {
				Write-Host Current certificate $cert.SerialNumber chain and revocation status is valid -ForegroundColor Green
			} else {
				Write-Warning "Current certificate $($cert.SerialNumber) chain is invalid due of the following errors:"
				$chain.ChainStatus | %{Write-Host $_.StatusInformation.trim() -ForegroundColor Red}
			}
		}
	}
	
	process {
		if ($_ -is [System.Security.Cryptography.X509Certificates.X509Certificate2]) {
			$status = $chain.Build($_)
			_getstatus_ $status $chain $_
		} else {
			if (!(Test-Path $Certificate)) {Write-Warning "Specified path is invalid"; return}
			else {
				if ((Resolve-Path $Certificate).Provider.Name -ne "FileSystem") {
					Write-Warning "Spicifed path is not recognized as filesystem path. Try again"; return
				} else {
					$Certificate = gi $(Resolve-Path $Certificate)
					switch -regex ($Certificate.Extension) {
					"\.CER|\.DER|\.CRT" {$cert.Import($Certificate.FullName)}
					"\.PFX" {
						if (!$Password) {$Password = Read-Host "Enter password for PFX file $certificate" -AsSecureString}
							$cert.Import($Certificate.FullName, $password, "UserKeySet")
						}
					"\.P7B|\.SST" {
						$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2Collection
						$cert.Import([System.IO.File]::ReadAllBytes($Certificate.FullName))
						}
					default {Write-Warning "Looks like your specified file is not a certificate file"; return}
					}
					$cert | %{
						$status = $chain.Build($_)
						_getstatus_ $status $chain $_
					}
					$cert.Reset()
					$chain.Reset()
				}
			}
		}
	}
}
# SIG # Begin signature block
# MIIIPAYJKoZIhvcNAQcCoIIILTCCCCkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUbRDcSlj31gB3Dj0E/HWIHY/w
# 5IKgggVaMIIFVjCCBD6gAwIBAgIQSX2g7+3+PL1oSJra3tEBIzANBgkqhkiG9w0B
# AQUFADCBlTELMAkGA1UEBhMCVVMxCzAJBgNVBAgTAlVUMRcwFQYDVQQHEw5TYWx0
# IExha2UgQ2l0eTEeMBwGA1UEChMVVGhlIFVTRVJUUlVTVCBOZXR3b3JrMSEwHwYD
# VQQLExhodHRwOi8vd3d3LnVzZXJ0cnVzdC5jb20xHTAbBgNVBAMTFFVUTi1VU0VS
# Rmlyc3QtT2JqZWN0MB4XDTA5MTAxNjAwMDAwMFoXDTEwMTAxNjIzNTk1OVowgcQx
# CzAJBgNVBAYTAlVTMQ4wDAYDVQQRDAUxNDYyMzERMA8GA1UECAwITmV3IFlvcmsx
# EjAQBgNVBAcMCVJvY2hlc3RlcjEUMBIGA1UECQwLTVMgMDgwMS0xN0ExGjAYBgNV
# BAkMETEzNTAgSmVmZmVyc29uIFJkMRowGAYDVQQKDBFYZXJveCBDb3Jwb3JhdGlv
# bjEUMBIGA1UECwwLU0VFRFUgVG9vbHMxGjAYBgNVBAMMEVhlcm94IENvcnBvcmF0
# aW9uMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA+BtkDUSRsr9qshYW
# 6mBLwe62RdoKaBiCZh1whKQbAqN58lmbN3fP2Qf6eheR03EyqPXq5gGQO8SpeeOn
# tDmlgR47dKFfawWKLEM4H189FJ6VHKD8Hmk1+/OAv/6F45HvbXOrGmisUgKplmzl
# tmot9uv04nyFlRXMPbHwKxNlWOdSSs1N9Y+q7y3kuSBm4bCqquqEFnm7gAzHt/A1
# 1CkT8f/0UP0ODKj0Cs/hc+b/xOCCL06SALYOYtMdBFwluBs85p2Bv1WcdUIELprz
# jnOjgoF4vk29UIUNkDZ5j2d0W0FCNd61ukm9faJMuU2/yw348sxclSoT18yOeC+Z
# vKc4lQIDAQABo4IBbzCCAWswHwYDVR0jBBgwFoAU2u1kdBScFDyr3ZmpvVsoTYs8
# ydgwHQYDVR0OBBYEFAu07ifjpHK32XeSDsdjIK4/R25LMA4GA1UdDwEB/wQEAwIH
# gDAMBgNVHRMBAf8EAjAAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMBEGCWCGSAGG+EIB
# AQQEAwIEEDBGBgNVHSAEPzA9MDsGDCsGAQQBsjEBAgEDAjArMCkGCCsGAQUFBwIB
# Fh1odHRwczovL3NlY3VyZS5jb21vZG8ubmV0L0NQUzBCBgNVHR8EOzA5MDegNaAz
# hjFodHRwOi8vY3JsLnVzZXJ0cnVzdC5jb20vVVROLVVTRVJGaXJzdC1PYmplY3Qu
# Y3JsMDQGCCsGAQUFBwEBBCgwJjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuY29t
# b2RvY2EuY29tMCEGA1UdEQQaMBiBFkpvZWwuQmVubmV0dEBYZXJveC5jb20wDQYJ
# KoZIhvcNAQEFBQADggEBAG5+It5AFsnqx1GDTuHxuExJGtpRYH6OatSs3eV507zz
# 5tyKbtCros6j92rvJOUfefk38saqbk81o5vMvEyQ/lQ7tp06NV0QBdt5WtoOnUZk
# u2lG4NcxiSz5vxQRF4+3mUZ77K3kRu6zY+zrauTTONmRPOdhYMMbKfZ67kePVNNv
# gnueXBxhd+xj5FJUVTW0qlks6+uYMKNM+MLvRxV83WUYwpnfcQyyvVILsVdw56qp
# OzOxIsQDc2flhqYVktPjL80fOXAPWzs88VXxoEkO3fvqHXi3VlWxMVV/861RORzk
# 5aleuMEp/2Ue1dJG279ATD1QDCHiG11Vz34Pdptf3FYxggJMMIICSAIBATCBqjCB
# lTELMAkGA1UEBhMCVVMxCzAJBgNVBAgTAlVUMRcwFQYDVQQHEw5TYWx0IExha2Ug
# Q2l0eTEeMBwGA1UEChMVVGhlIFVTRVJUUlVTVCBOZXR3b3JrMSEwHwYDVQQLExho
# dHRwOi8vd3d3LnVzZXJ0cnVzdC5jb20xHTAbBgNVBAMTFFVUTi1VU0VSRmlyc3Qt
# T2JqZWN0AhBJfaDv7f48vWhImtre0QEjMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3
# AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisG
# AQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBSLcWVsGmEs
# y3aqToxGv4N7GtZKaTANBgkqhkiG9w0BAQEFAASCAQBKs1LvUwZC+0Bs9/3D03/L
# xp9NYjTfnXfeKI73KOnw4RMKY4rnnbEi0eLxsKOyFTDLbvEkO0dPeRa8LVANktgx
# H2zHECjyud949UaU1CnAhJhbx0EHQQatumsBEcaQqO/vJGTTE3F1faxIbQoyxkZC
# bax1ISAF1JeR8avSDgLEEDj1kqTP7a5lNTO0k9CX0kvmF7GXGBwEJJ0XZh1ipCFW
# PEF9xdE3wP3iXs2rVk8LZIKx6Iz14PPhp/004hKKPUolAg9PPJM+fiN6vsluTpoH
# tDe5OXi71/Hpl51E9XNpRz/kUyB5MSxvsl9bf0DTHwWTa4hOrvWUBpkPU10FT7y6
# SIG # End signature block
