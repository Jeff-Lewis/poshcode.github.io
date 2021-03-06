<#
.SYNOPSIS
A very simple function to debug a Regex search operation and show any 'Match' 
results.
.DESCRIPTION
Sometimes it is easier to correct any regex usage if each match can be shown 
in context. This function will show each successful result in a separate 
colour, including the strings both before and after the match. Using the -F
switch will allow only the first of any matches to be returned.
.EXAMPLE
Debug-Regex '\b[A-Z]\w+' 'Find capitalised Words in This string' -first
Use the -F switch to return only the first match.

MATCHES  ---------------<match>--------------------
1 [<Find> capitalised Words in This string]
.EXAMPLE
Debug-Regex '\b[0-9]+\b' 'We have to find numbers like 123 and 456 in this'

MATCHES  ---------------<match>--------------------
1 [We have to find numbers like <123> and 456 in this]
2 [We have to find numbers like 123 and <456> in this]
.NOTES
Based on an idea from the book 'Mastering Regular Expressions' by J.Friedl,
page 429. 
#>


function Debug-Regex {
   param ([Parameter(mandatory=$true)][regex]$regex,
          [Parameter(mandatory=$true)][string]$string,
          [switch]$first)
   $m = $regex.match($string)
   if (!$m.Success) {
      Write-Host "No Match using Regex '$regex'" -Fore Yellow
      return
   }
   $count = 1
   Write-Host "MATCHES  ---------------<" -Fore Yellow -NoNewLine
   Write-Host "match"                     -Fore White  -NoNewLine
   Write-Host ">--------------------"     -Fore Yellow
   while ($m.Success) {
      Write-Host "$count $($m.result('[$`<'))" -Fore Yellow -NoNewLine 
      Write-Host "$($m.result('$&'))"          -Fore White  -NoNewLine 
      Write-Host "$($m.result('>$'']'))"       -Fore Yellow 
      if ($first) {
         return
      }
      $count++
      $m = $m.NextMatch()
   }
}
