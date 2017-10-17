﻿## Simplest RSS Reader
####################################################################################################
## Save this file as Start-RssReader.ps1
## Run it like:
##     .\Start-RssReader "http://feeds.feedburner.com/powerscripting", "http://HuddledMasses.org/feed"
## And then:
##    Get-RSS          # to (re)fetch the feeds and view
##    Show-RSS         # to view without re-fetching
##    Open-RSSItem 2   # to open an item in your browser
####################################################################################################
PARAM( 
   [string[]]$RssReaderUrls = $(do{
                           $k = Read-Host "Specify an RSS Feed URL (hit Enter when done)"
                           if($k) {write-output $k}
                        } while($k) )
)

function global:Get-RSS {
   $webClient = New-Object System.Net.WebClient
   $global:RssReaderNews = $RssReaderUrls | % { [xml]$webClient.DownloadString( $_ ) } | 
                            % { $_.rss.channel.item } | 
                            Sort { [DateTime]$_.pubDate } -Desc
   Show-RSS
}

function global:Show-RSS($days=7) {
   $script:index = -1
   $global:RssReaderNews | Where { ([DateTime]$_.pubDate).AddDays($days) -gt [DateTime]::Now } | 
           ft @{l="Index";e={return $script:index++}},@{l="Day";e={$_.pubDate.split(",",2)[0]}}, title, link -auto
}

function global:Open-RssItem($index=0) {
   [Diagnostics.Process]::Start( $($global:RssReaderNews[$index].link) )
}
$global:RssReaderUrls = $RssReaderUrls
Get-RSS
