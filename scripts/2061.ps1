#####################################################################
# Issue certificate.ps1
# Version 1.5
#
# Issues certificate request from a pending request
#
# For this function to succeed, the certificate request must be pending
#
# Vadims Podans (c) 2010
# http://en-us.sysadmins.lv/
#####################################################################
#requires -Version 2.0

function Issue-PendingRequest {
[CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFomPipeline = $true)]
        [string]$CAConfig,
        [Parameter(Mandatory = $true)]
        [int]$RequestID
    )
    try {$CertAdmin = New-Object -ComObject CertificateAuthority.Admin}
    catch {Write-Warning "Unable to instantiate ICertAdmin2 object!"; return}
    try {
        $status = switch ($CertAdmin.ResubmitRequest($CAConfig,$RequestID)) {
            0 {"The request was not completed."}
            1 {"The request failed."}
            2 {"The request was denied"}
            3 {"The certificate was issued."}
            4 {"The certificate was issued separately."}
            5 {"The request was taken under submission."}
            6 {"The certificate is revoked."}
        }
    }
    catch {$_; return}
    Write-Host "Operation status for the request '$RequestID': $ststus"
}
