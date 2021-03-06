#requires -version 2.0
<#
.Synopsis
   Downloads Channel 9 Defrag Tool Episode Video
.DESCRIPTION
   Downloads Channel 9 Defrag Tool Episode Video in the format selected and to a given path.
.EXAMPLE
   Downloads all shows in WMV format to the default Downloads Folder for the user.

   Get-DefragToolsShow -All -VideoType wmv

.EXAMPLE
   Downloads only the last show of the series in MP4 format

   Get-DefragToolsShow -Last -VideoType MP4
.NOTES
    Author: Carlos Perez carlos_perez[at]darkoperator.com
#>
function Get-DefragToolsShow
{
    [CmdletBinding()]
    Param
    (

        [Parameter(Mandatory=$false,
                   Position=0)]
        $Path = "$($env:USERPROFILE)\downloads",

        [Parameter(Mandatory=$false,
        ParameterSetName="All")]
        [switch]$All = $true,

        [Parameter(Mandatory=$false,
        ParameterSetName="Last")]
        [switch]$Last = $true,

        [Parameter(Mandatory=$false)]
        [ValidateSet("MP4HD","MP4","WMVHD","WMV")]
        [string]$VideoType =  "MP4HD"
        
    )

    Begin
    {
        $WebClient =  New-Object System.Net.WebClient
        $Global:downloadComplete = $false

        $eventDataComplete = Register-ObjectEvent $WebClient DownloadFileCompleted `
            -SourceIdentifier WebClient.DownloadFileComplete `
            -Action {$Global:downloadComplete = $true}
        $eventDataProgress = Register-ObjectEvent $WebClient DownloadProgressChanged `
            -SourceIdentifier WebClient.DownloadProgressChanged `
            -Action { $Global:DPCEventArgs = $EventArgs }    

        # Lets change to the proper path
        Set-Location (Resolve-Path $Path).Path
    }
    Process
    {
        switch ($PsCmdlet.ParameterSetName)
        {
            "All"{$all = $true}
            "Last"{$all =  $false}

        }

        switch ($VideoType)
        {
            "MP4HD"  {$feedURL = "http://channel9.msdn.com/Shows/Defrag-Tools/feed/mp4high"} 
            "MP4"    {$feedURL = "http://channel9.msdn.com/Shows/Defrag-Tools/feed/mp4"}
            "WMVHD"  {$feedURL = "http://channel9.msdn.com/Shows/Defrag-Tools/feed/wmvhigh"}
            "WMV"    {$feedURL = "http://channel9.msdn.com/Shows/Defrag-Tools/feed/wmv"}
        }

        $feed = [xml]$WebClient.DownloadString($feedURL)


        if ($All)
        {
            foreach ($episode in $feed.rss.channel.Item)
            {
                # Create a proper URI for parsing
                $episodeURL = [System.Uri]$episode.enclosure.url

                # Get the episode file name
                $file = $episodeURL.Segments[-1]

                #Check if the file exists if it does skip it
                if (!(Test-Path $file))
                {
                    Write-Progress -Activity 'Downloading file' -Status $file
                    $WebClient.DownloadFileAsync($episodeURL,$file)

                     while (!($Global:downloadComplete)) 
                     {                
                        $pc = $Global:DPCEventArgs.ProgressPercentage
                        if ($pc -ne $null) 
                        {
                            Write-Progress -Activity 'Downloading file' -Status $file -PercentComplete $pc
                        }
                    }
                    $Global:downloadComplete = $false
                }
            }
        }
        else
        {
            $episodeURL = [System.Uri]$feed.rss.channel.Item[0].enclosure.url
            # Get the episode file name
            $file = $episodeURL.Segments[-1]

            #Check if the file exists if it does skip it
            if (!(Test-Path $file))
            {
                Write-Progress -Activity 'Downloading file' -Status $file
                $WebClient.DownloadFileAsync($episodeURL,$file)
                # Lets wait for it to finish
                while (!($Global:downloadComplete)) 
                {                
                    $pc = $Global:DPCEventArgs.ProgressPercentage
                    if ($pc -ne $null) 
                    {
                        Write-Progress -Activity 'Downloading file' -Status $file -PercentComplete $pc
                    }
                }
            }
        }
    }
    End
    {
        Unregister-Event -SourceIdentifier WebClient.DownloadProgressChanged
        Unregister-Event -SourceIdentifier WebClient.DownloadFileComplete
        $Global:downloadComplete = $null
        $Global:DPCEventArgs = $null
        [GC]::Collect()    
    }
}
