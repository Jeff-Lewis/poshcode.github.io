#requires -Version 2.0

<#
    .Synopsis
      
        Script that will produce table of leaders in a give category.

    .Description

        Just some fun with regex/ xml. :)
        It will grab SG 2011 Leader Board for a given category.
        Than parse the string, convert it into XML, create custom objects and in the end - produce nice table.
        Not really best practices, but well... it's all about display this time.
        Goes in loop, so it should keep leaderboard.
        And if you miss you name in topX - add it using -Name parameter. :)

    .Example

        Watch-SG2011LeaderBoard
        Starts using defaults: Advanced category, Top 10 users, 5 seconds delay, and 2011 SG url.
        
    .Example

        Watch-SG2011LeaderBoard -Categeroy Beg -Name ScriptingWife
        Show Beginner category, and include ScriptingWife regardless her current position. :)

    #>

[CmdletBinding()]
param (
    # Leader Board category that you want to look up.
    [ValidateSet('Adv','Advanced','Beg','Beginner')]
    [string]$Category = 'Adv',
    
    # Name of the person that you want to be included no matter what position it holds.
    [string]$Name,
    
    # Total number of TOP you would like to include (mind you window size...)
    [int]$Top = 10,
    
    # Delay between list will be refreshed for you.
    [int]$Delay = 5,
    
    # URL to main site, may be handy for next year... ;)
    [string]$URL = 'https://2011sg.poshcode.org/Reports/TopUsers'
)

$WebClient = New-Object Net.WebClient
switch -regex ($Category) {
    "^A.*" {
        $URL = $URL + '?filter=Advanced'
    }
    "^B.*" {
        $URL = $URL + '?filter=Beginner'
    }
    default {
        Write-Verbose "Why would I handle alien's/ divine intervention? Isn't parameter validation enough? ;)"
    }
}

$Title = "$Category Scripting Games Leaderboard"

if ($Name) {
    $Filter = { ($TopDisplayed++ -lt $Top) -or ($_.Name -match $Name) }
} else {
    $Filter = { $TopDisplayed++ -lt $Top }
}
while ($True) {
    
    $WebClient.DownloadString($URL) | Select-String -Pattern '(<table>[\s\S]*?</table>)' | Select -ExpandProperty Matches |
        ForEach-Object {
            # Probably should have some replacement table for &specials; -> not know them well enough so just remove them for now...
            # XML will try to abuse those, so we need to 'strip' them... :(
            # Also remove <a ... > </a> to take names 'up' in XML schema.
            # And last but not least - remove all whitespaces except for those between words... :)
            
            $Table = $_.Groups[0].Value -replace '&\w+?;' -replace '</?a.*?>' -replace '\s*(?!\w)' -replace '(?<!\w)\s*'
        }
    try {
        $XML = [xml]$Table
    } catch {
        Write-Host "Sorry, could not change to XML. Take a look at error below for more details..."
        Write-Error $_
        exit
    }
        
    # Got here so we should have $XML with nice struct. Let's parse it and show some results... :)
    # Parsing first to create object. Than sort/ where to show all top + named if not in top...
    
    $TopDisplayed = 0
    
    Clear-Host
    Write-Host $Title
    "=" * $Title.Length | Out-Default
    "Last update: $(Get-Date -DisplayHint Time)"
    $XML.table.tr | Select-Object -Skip 1 | ForEach-Object { 
        New-Object PSObject -Property @{ 
            Name = $_.td[0]
            Total = [double]($_.td[1])
            Rated = [int]($_.td[2])
            Notes = [int]($_.td[3])
        }
    } | Sort-Object -Property Total -Descending | Where-Object $Filter |
        Format-Table Name, Total, Rated, Notes -AutoSize
    Start-Sleep -Seconds $Delay
}
