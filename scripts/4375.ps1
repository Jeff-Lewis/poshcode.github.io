#requires -module BetterCredentials

# REQUIRED:
# Get a key from https://datamarket.azure.com/account/keys 
# Make sure you have a subscription to http://datamarket.azure.com/dataset/bing/search

# FIRST USE:
# Each user needs to pass an ApiKey the first time you import this module
# Replace your key for the AAA key below:
# Import-Module Bing -ArgumentList AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA= -Force
# After that you can just Import-Module Bing
param(
  $ApiKey,

  [System.Management.Automation.PSCredential]
  [System.Management.Automation.Credential()]
  $Credential = $(if($ApiKey){ Get-Credential -User BingApiKey -Password $ApiKey -Store } else { Get-Credential -User BingApiKey })
)

Add-Type -Assembly System.Web

$Ofs = " "

$Selectors = @{
  Web = @{
    Format = "{0} {1}"
    Fields = "Title","Url"
  }
  News = @{
    Format = "{0} (from {2}) {1}"
    Fields = "Title","Url","Source"
  }
  Image = @{
    Format = "{0} ({2}x{3}) {1}"
    Fields = "Title","MediaUrl","Width","Height"
  }
  SpellingSuggestions = @{ 
    Format = "{0}"
    Fields = "Value"
  }
}

function Search-Bing {
  #.Synopsis
  #   Search Bing Web, News, Images, or SpellingSuggestions
  #.Notes
  #   Version 1.0 - Wrote this version after Bing switched to datamarket APIs
  param(
    # The search terms
    [Parameter(Position=0, Mandatory=$true, ValueFromRemainingArguments=$true, ValueFromPipeline=$true)]
    [String[]]$Query,

    # The type of search
    [ValidateSet("Web","News","Image","SpellingSuggestions")]
    $Noun = "Web",

    # The number of results to fetch
    [ValidateRange(0,5)]
    [int]$Count = 3,

    # The number of results to skip
    [int]$Skip = 0
  )
  $Query = [Web.HttpUtility]::UrlEncode("'$Query'")

  $Search = "https://api.datamarket.azure.com/Bing/Search/${Noun}?Query=${Query}&`$top=$Count&`$skip=$Skip"

  $global:BingResults = Invoke-WebRequest -Credential $Credential -Uri $Search
  $global:BingEntries = ([xml]$BingResults.Content).feed.entry.content.properties

  $Selector = $Selectors.$Noun.Fields -join "' or local-name() = '"
  $Selector =  "*[local-name() = '$Selector']/text()"
  foreach($entry in $BingEntries) {
    $Selectors.$Noun.Format -f $entry.SelectNodes($Selector).Value
  }

}
