## Find-String.ps1
########################################################################################################################
## Find-String is basically a PowerShell 1.0 wrapper around { select-string } which will append the "Matches" to it
## Highlight-Matches takes a collections of MatchInfo objects and prints them out, highlighting the actual match.
## 
## Based on:
## http://weblogs.asp.net/whaggard/archive/2007/03/23/powershell-script-to-find-strings-and-highlight-them-in-the-output.aspx
##
## It should be noted that this DOES NOT return objects on the pipeline unless you specify -passthru
## If you do specify passthru, it will Add the "Matches" property to the MatchInfo objects, 
## making them more like ## the 2.0 MatchInfo object.
########################################################################################################################
function Find-String {
PARAM( [regex] $pattern = $(Read-Host "Regular expression search pattern")
     , [string] $filter = "*.*"
	  , [switch] $recurse
	  , [switch] $caseSensitive
     , [switch] $summary
)

$v2 = [bool](new-object Microsoft.PowerShell.Commands.MatchInfo | gm "Matches")

if ($pattern.ToString() -eq "") { throw "Nothing to search for! Please provide a search pattern!" }

if( (-not $caseSensitive) -and (-not $pattern.Options -match "IgnoreCase") ) {
	$pattern = New-Object regex $pattern.ToString(),@($pattern.Options,"IgnoreCase")
}

if($summary) {
   [string[]] $summaryText = ""
   $summaryText += "Matches  Lines  FileName"
   $summaryText += "-------  -----  --------"

   $totalCount = 0; $totalLines = 0;
}
# Do the actual find in the files
Get-ChildItem -recurse:$recurse -filter:$filter |
   foreach { 
      if($summary) {
         $fileCount = 0; $lineCount = 0;
      }
      if($v2) {
         $select = "Select-String -input `$_ -caseSensitive:`$caseSensitive -pattern:`$pattern -AllMatches"
      } else {
         $select = "Select-String -input `$_ -caseSensitive:`$caseSensitive -pattern:`$pattern"
      } 
      
      iex $select | foreach {
         if(!$v2) {
            Add-Member -Input $_ -MemberType NoteProperty -Name "Matches" -Value $pattern.Matches($_.Line) -ErrorAction SilentlyContinue
         }

         Write-Output $_
         
         if($summary) {
   		   $lineCount++
   		   $fileCount += $_.Matches.Count
         }
	   }
      if($summary) {
         $totalCount += $fileCount;
         $totalLines += $lineCount;
         if( $fileCount -gt 0) {
            $summaryText += "{0,7}  {1,5}  {2}" -f $fileCount, $lineCount, $_
         }
      }
   }
if($summary) {
   $summaryText += "-------  -----  -----"
   $summaryText += "{0,7}  {1,5}  TOTALS" -f $totalCount, $totalLines
   $summaryText += ""
   $summaryText | Out-Host
}

}

# Write the line with the pattern highlighted in red
function Highlight-Matches
{
   PARAM ([Microsoft.PowerShell.Commands.MatchInfo[]]$match, [Switch]$Passthru)
   BEGIN {
      if($match) { 
         $match | Write-Host-HighlightMatches
      }
   }
   PROCESS { 
      if($_ -and ($_ -isnot [Microsoft.PowerShell.Commands.MatchInfo])) {
         throw "Expected Microsoft.PowerShell.Commands.MatchInfo objects on the pipeline"
      } elseif($_) {
         Write-Host ("{0} {1,5} {2,3}: " -f $_.FileName, "($($_.LineNumber))", $_.matches.Count) -nonewline
         $index = 0;
         foreach($match in $_.Matches) {
            Write-Host $_.line.SubString($index, $match.Index - $index) -nonewline
            Write-Host $match.Value -ForegroundColor Red -nonewline
            $index = $match.Index + $match.Length
         }
         if($index -lt $_.line.Length) {
            Write-Host $_.line.SubString($index) -nonewline
         }
         Write-Host
         
         if($Passthru) { $_ }
      }
   }
}

