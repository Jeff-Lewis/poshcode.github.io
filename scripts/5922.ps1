<#
.SYNOPSIS
Gets direct youtube links for given search term

.SYNTAX
GetYoutubeLinks [-searchTerm <String[]>] [-numOfPages <Int[]>] [-FilePath <String[]>]

.DESCRIPTION
Function takes search term and number of pages as input parameters. Depending on number of pages given
function will return all direct video url from these pages for given search parameter. If filePath is 
specified the function will write links to file instead of outputing them to screen.
It is implemented via web page parsing, not via REST API, so script does not need OAuth Authorization
Powershell v3 or higher is assumed as it relies on Invoke-Webrequest

.EXAMPLE
GetYoutubeLinks -searchTerm 'I like powershell' -numOfPages 3

.EXAMPLE
GetYoutubeLinks -searchTerm 'I like powershell' -numOfPages 7 -filePath "D:\ILikePowershell.txt"
#>

function GetYoutubeLinks ($searchTerm, $numOfPages, [string]$filePath)
{
  $youtube = 'https://www.youtube.com'  
  $allLinks = New-Object System.Collections.ArrayList

  Function DedupeArrLst($resultArrLst)
  {
    $deduped = New-Object System.Collections.ArrayList
    foreach ($entry in $resultArrLst)
    {
      if (!($deduped.Contains($entry)))
      {
        $deduped.Add($entry)
      }
    } 
    
    return $deduped;
  }
   
  function ParseLinks($web_links)
  {
    foreach($link in $web.Links)
      {
       if(($link.href -like '*/watch?v=*') -and ($link.href -notlike '*;list=*'))
       {
         $linkEntry = $youtube + $link.href
         $allLinks.Add($linkEntry)  
       }      
      }
   }

  if($numOfPages -eq 1)
  {
    $youTubePage = "$youtube" + "/results?search_query=" + $searchTerm
    $web = Invoke-WebRequest -Uri "$youTubePage"
    
    ParseLinks -web_links $web  
  }

  else
  {
    for($i=0; $i -le $numOfPages; $i++)
    {
      $youTubePage = "$youtube" + "/results?search_query=" + $searchTerm + "&page=$i"
      $web = Invoke-WebRequest -Uri "$youTubePage"

      ParseLinks $web     
    }
  }
  
  if($filePath.Length -lt 1)
  {
    DedupeArrLst($allLinks)   
  }

  else
  {
    foreach($i in DedupeArrLst($allLinks))
    {
      if($i -match '^http.*')
      {
        $i >> $filePath
      }
    }
  }
}


