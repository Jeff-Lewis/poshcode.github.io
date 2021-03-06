#This is actually code written from scratch (not an update to anyone else’s script) based on a problem posted in the PowerShell.org forums. The original posting can be found here: http://powershell.org/wp/forums/topic/how-to-make-this-more-useful-for-my-situation/ and the following is a copy of that post:

Hopefully I understand this correctly. Part 1: You're attempting to find all Active Directory users who have an old server name used in their HomeDirectory path or in their ProfilePath. Part 2: you want that path replaced with exactly the same thing except for the server name to be the new server. Correct?
Here's a fairly simple script to accomplish that task:

$OldServer = 'OldServer'
$NewServer = 'NewServer'
 
Import-Module ActiveDirectory
Get-ADUser -Filter "Enabled -eq 'true' -and HomeDirectory -like '*$OldServer*' -or ProfilePath -like '*$OldServer*'" -Properties HomeDirectory, ProfilePath |
ForEach-Object {
    if ($_.HomeDirectory -like "*$OldServer*") {
        Set-ADUser -Identity $_.DistinguishedName -HomeDirectory $($_.HomeDirectory -replace $OldServer, $NewServer)
    }
    if ($_.ProfilePath -like "*$OldServer*") {
        Set-ADUser -Identity $_.DistinguishedName -ProfilePath $($_.ProfilePath -replace $OldServer, $NewServer)
    }
}
If you want something a little more advanced, you can save the following script as a ps1 file and run the file specifying the names of the old and new server via parameter input. You can specify if you want the users who are changed to be returned via the PassThru parameter and you can also specify the WhatIf parameter to see which users will be changed before actually making the changes:

#Requires -Modules ActiveDirectory
 
[CmdletBinding()]
param (
    [ValidateNotNullOrEmpty()]
    [string]$OldServer = 'OldServer',
 
    [ValidateNotNullOrEmpty()]
    [string]$NewServer = 'NewServer',
 
    [switch]$PassThru,
 
    [switch]$WhatIf
)
 
$Params = @{}
If ($PSBoundParameters['PassThru']) {
            $Params.PassThru = $true
}
 
If ($PSBoundParameters['WhatIf']) {
            $Params.WhatIf = $true
}
 
 
Get-ADUser -Filter "Enabled -eq 'true' -and HomeDirectory -like '*$OldServer*' -or ProfilePath -like '*$OldServer*'" -Properties HomeDirectory, ProfilePath |
ForEach-Object {
    if ($_.HomeDirectory -like "*$OldServer*") {
        Set-ADUser -Identity $_.DistinguishedName -HomeDirectory $($_.HomeDirectory -replace $OldServer, $NewServer) @Params
    }
    if ($_.ProfilePath -like "*$OldServer*") {
        Set-ADUser -Identity $_.DistinguishedName -ProfilePath $($_.ProfilePath -replace $OldServer, $NewServer) @Params
    }
}
These scripts are something I came up with in just a few minutes so I would recommend thoroughly testing them before attempting to use them in production (at your own risk).

Mike F Robbins | PowerShell MVP | Leader & Co-Founder of the Mississippi PowerShell User Group | mikefrobbins.com | @mikefrobbins
