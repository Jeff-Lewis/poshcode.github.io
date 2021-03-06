param([Alias("copy","demo")][Switch]$Pasteable)
# This should go OUTSIDE the prompt function, it doesn't need re-evaluation
# We're going to calculate a prefix for the window title 
# Our basic title is "PoSh - C:\Your\Path\Here" showing the current path
if(!$global:WindowTitlePrefix) {
   # But if you're running "elevated" on vista, we want to show that ...
   if( ([System.Environment]::OSVersion.Version.Major -gt 5) -and ( # Vista and ...
         new-object Security.Principal.WindowsPrincipal (
            [Security.Principal.WindowsIdentity]::GetCurrent()) # current user is admin
            ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) )
   {
      $global:WindowTitlePrefix = "PoSh ${Env:UserName}@${Env:UserDomain} (ADMIN)"
   } else {
      $global:WindowTitlePrefix = "PoSh ${Env:UserName}@${Env:UserDomain}"
   }
}

if($Pasteable) {
   function global:prompt {
      Write-host "<#PS " -NoNewLine -fore gray
      # FIRST, make a note if there was an error in the previous command
      $err = !$?

      # Make sure Windows and .Net know where we are (they can only handle the FileSystem)
      [Environment]::CurrentDirectory = (Get-Location -PSProvider FileSystem).ProviderPath
      # Also, put the path in the title ... (don't restrict this to the FileSystem
      $Host.UI.RawUI.WindowTitle = "{0} - {1} ({2})" -f $global:WindowTitlePrefix,$pwd.Path,$pwd.Provider.Name
      
      # Determine what nesting level we are at (if any)
      $Nesting = "$([char]0xB7)" * $NestedPromptLevel

      # Generate PUSHD(push-location) Stack level string
      $Stack = "+" * (Get-Location -Stack).count
      
      # my New-Script and Get-PerformanceHistory functions use history IDs
      # So, put the ID of the command in, so we can get/invoke-history easier
      # eg: "r 4" will re-run the command that has [4]: in the prompt
      $global:lastCommandId = (Get-History -count 1).Id
      $global:nextCommandId = $global:lastCommandId + 1
      # Output prompt string
      # If there's an error, set the prompt foreground to "Red", otherwise, "Yellow"
      if($err) { $fg = "Red" } else { $fg = "Yellow" }
      # Notice: no angle brackets, makes it easy to paste my buffer to the web
      Write-Host "[${Nesting}${nextCommandId}${Stack}]" -NoNewLine -Fore $fg   
      Write-host " #>" -NoNewLine -fore gray
      return " "
   }
} else {
   function global:prompt {
      # FIRST, make a note if there was an error in the previous command
      $err = !$?

      # Make sure Windows and .Net know where we are (they can only handle the FileSystem)
      [Environment]::CurrentDirectory = (Get-Location -PSProvider FileSystem).ProviderPath
      # Also, put the path in the title ... (don't restrict this to the FileSystem
      $Host.UI.RawUI.WindowTitle = "{0} - {1} ({2})" -f $global:WindowTitlePrefix,$pwd.Path,$pwd.Provider.Name
      
      # Determine what nesting level we are at (if any)
      $Nesting = "$([char]0xB7)" * $NestedPromptLevel

      # Generate PUSHD(push-location) Stack level string
      $Stack = "+" * (Get-Location -Stack).count
      
      # my New-Script and Get-PerformanceHistory functions use history IDs
      # So, put the ID of the command in, so we can get/invoke-history easier
      # eg: "r 4" will re-run the command that has [4]: in the prompt
      $global:lastCommandId = (Get-History -count 1).Id
      $global:nextCommandId = $global:lastCommandId + 1
      # Output prompt string
      # If there's an error, set the prompt foreground to "Red", otherwise, "Yellow"
      if($err) { $fg = "Red" } else { $fg = "Yellow" }
      # Notice: no angle brackets, makes it easy to paste my buffer to the web
      Write-Host "[${Nesting}${nextCommandId}${Stack}]:" -NoNewLine -Fore $fg   
      return " "
   }
}

# SIG # Begin signature block
# MIIIDQYJKoZIhvcNAQcCoIIH/jCCB/oCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU5rw7+Fu1OTKOakwxczBw+raG
# 71egggUrMIIFJzCCBA+gAwIBAgIQKQm90jYWUDdv7EgFkuELajANBgkqhkiG9w0B
# AQUFADCBlTELMAkGA1UEBhMCVVMxCzAJBgNVBAgTAlVUMRcwFQYDVQQHEw5TYWx0
# IExha2UgQ2l0eTEeMBwGA1UEChMVVGhlIFVTRVJUUlVTVCBOZXR3b3JrMSEwHwYD
# VQQLExhodHRwOi8vd3d3LnVzZXJ0cnVzdC5jb20xHTAbBgNVBAMTFFVUTi1VU0VS
# Rmlyc3QtT2JqZWN0MB4XDTEwMDUxNDAwMDAwMFoXDTExMDUxNDIzNTk1OVowgZUx
# CzAJBgNVBAYTAlVTMQ4wDAYDVQQRDAUwNjg1MDEUMBIGA1UECAwLQ29ubmVjdGlj
# dXQxEDAOBgNVBAcMB05vcndhbGsxFjAUBgNVBAkMDTQ1IEdsb3ZlciBBdmUxGjAY
# BgNVBAoMEVhlcm94IENvcnBvcmF0aW9uMRowGAYDVQQDDBFYZXJveCBDb3Jwb3Jh
# dGlvbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMfUdxwiuWDb8zId
# KuMg/jw0HndEcIsP5Mebw56t3+Rb5g4QGMBoa8a/N8EKbj3BnBQDJiY5Z2DGjf1P
# n27g2shrDaNT1MygjYfLDntYzNKMJk4EjbBOlR5QBXPM0ODJDROg53yHcvVaXSMl
# 498SBhXVSzPmgprBJ8FDL00o1IIAAhYUN3vNCKPBXsPETsKtnezfzBg7lOjzmljC
# mEOoBGT1g2NrYTq3XqNo8UbbDR8KYq5G101Vl0jZEnLGdQFyh8EWpeEeksv7V+YD
# /i/iXMSG8HiHY7vl+x8mtBCf0MYxd8u1IWif0kGgkaJeTCVwh1isMrjiUnpWX2NX
# +3PeTmsCAwEAAaOCAW8wggFrMB8GA1UdIwQYMBaAFNrtZHQUnBQ8q92Zqb1bKE2L
# PMnYMB0GA1UdDgQWBBTK0OAaUIi5wvnE8JonXlTXKWENvTAOBgNVHQ8BAf8EBAMC
# B4AwDAYDVR0TAQH/BAIwADATBgNVHSUEDDAKBggrBgEFBQcDAzARBglghkgBhvhC
# AQEEBAMCBBAwRgYDVR0gBD8wPTA7BgwrBgEEAbIxAQIBAwIwKzApBggrBgEFBQcC
# ARYdaHR0cHM6Ly9zZWN1cmUuY29tb2RvLm5ldC9DUFMwQgYDVR0fBDswOTA3oDWg
# M4YxaHR0cDovL2NybC51c2VydHJ1c3QuY29tL1VUTi1VU0VSRmlyc3QtT2JqZWN0
# LmNybDA0BggrBgEFBQcBAQQoMCYwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmNv
# bW9kb2NhLmNvbTAhBgNVHREEGjAYgRZKb2VsLkJlbm5ldHRAWGVyb3guY29tMA0G
# CSqGSIb3DQEBBQUAA4IBAQAEss8yuj+rZvx2UFAgkz/DueB8gwqUTzFbw2prxqee
# zdCEbnrsGQMNdPMJ6v9g36MRdvAOXqAYnf1RdjNp5L4NlUvEZkcvQUTF90Gh7OA4
# rC4+BjH8BA++qTfg8fgNx0T+MnQuWrMcoLR5ttJaWOGpcppcptdWwMNJ0X6R2WY7
# bBPwa/CdV0CIGRRjtASbGQEadlWoc1wOfR+d3rENDg5FPTAIdeRVIeA6a1ZYDCYb
# 32UxoNGArb70TCpV/mTWeJhZmrPFoJvT+Lx8ttp1bH2/nq6BDAIvu0VGgKGxN4bA
# T3WE6MuMS2fTc1F8PCGO3DAeA9Onks3Ufuy16RhHqeNcMYICTDCCAkgCAQEwgaow
# gZUxCzAJBgNVBAYTAlVTMQswCQYDVQQIEwJVVDEXMBUGA1UEBxMOU2FsdCBMYWtl
# IENpdHkxHjAcBgNVBAoTFVRoZSBVU0VSVFJVU1QgTmV0d29yazEhMB8GA1UECxMY
# aHR0cDovL3d3dy51c2VydHJ1c3QuY29tMR0wGwYDVQQDExRVVE4tVVNFUkZpcnN0
# LU9iamVjdAIQKQm90jYWUDdv7EgFkuELajAJBgUrDgMCGgUAoHgwGAYKKwYBBAGC
# NwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgor
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUAYxB1OGv
# +gSNgLzV07nPJLNuFvQwDQYJKoZIhvcNAQEBBQAEggEAFM65fpcjQcDiRslwg9hl
# Mf8sVPS5hOxSFkOH6SuOXOFggJTnpqH7Oiz9/67y7ndGhmb4h22WsW3sWIS29zGt
# ZchjJk8mKcTzZB8foS0xJNLbYu8yGzDRdItUN3Hq1bvK+1B8RIcpY7NfTshQmsiD
# ZWzhBM82vaGp03cXzzLrAhiKDIcFI43P2LQbjz5rtcl3aJHiK0y9pYq5v9Fk76jk
# B5oNwvbWi9TLt8GEUYp48zRXLYP/Nnr3HJLcA4BHzfmAjopZGw54Oprr87LqXxv3
# OrArwdsdjw6HOMk2NW0txZm1f0wR3O6Tt2KZjWzB0Ru7GjHkKj618OVebDvON755
# lw==
# SIG # End signature block

