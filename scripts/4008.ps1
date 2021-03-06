function Get-SHA512([System.IO.FileInfo] $file = $(throw 'Usage: Get-MD5 [System.IO.FileInfo]'))
{
  	$stream = $null
  	$cryptoServiceProvider = [System.Security.Cryptography.SHA512CryptoServiceProvider]
  	$hashAlgorithm = new-object $cryptoServiceProvider
  	try 
    {
      $stream = $file.OpenRead()
    }
  	catch { return $null }
  	$hashByteArray = $hashAlgorithm.ComputeHash($stream)
  	$stream.Close()
  	trap
  	{
   		if ($stream -ne $null) {$stream.Close()}
      return $null
    } 	
    foreach ($byte in $hashByteArray) { if ($byte -lt 16) {$result += “0{0:X}” -f $byte } else { $result += “{0:X}” -f $byte }}
    return [string]$result
}

$starttime=[datetime]::now
write-host "FindDupe.ps1 - find and optionally delete duplicate files. FindDupe.ps1 /help or FindDupe.ps1 /h for usage options."
$m = 0
$args3=$args
$args2=$args3|?{$_ -ne "/delete" -and $_ -ne "/recurse" -and $_ -ne "/hidden" -and $_ -ne "/h" -and $_ -ne "/help"}
if ($args3 -eq "/help" -or $args3 -eq "/h")
{
	""
	"Usage:"
	"       PS>.\FindDupe.ps1 <directory/file #1> <directory/file #2> ... <directory/file #N> [-delete] [-noprompt] [-recurse] [-help]"
	"Options:"
	"       /recurse recurses through all subdirectories of any specified directories."
	"       /delete prompts to delete duplicates (user must be careful not to select delete for all copies)."	
	"	      /hidden checks hidden files, default is to ignore hidden files."
	"	      /help displays this usage option data, and ignores all other arguments."
	""
	"Examples:"
	"          PS>.\finddupe.ps1 c:\data d:\finance /recurse"
	"          PS>.\finddupe.ps1 d: -recurse /delete"
	"          PS>.\finddupe.ps1 c:\users\alice\pictures\ /recurse /delete"
 	exit
}


$files=@(dir -ea 0 $args2 -recurse:$([bool]($args3 -eq "/recurse")) -force:$([bool]($args3 -eq "/hidden")) |?{$_.psiscontainer -eq $false})|sort length
if ($files.count -lt 2) {"Not enough files specified."; exit}
$hashname=New-Object 'system.collections.generic.dictionary[[string],[system.collections.generic.list[string]]]'
$hashsize=0
$hashfiles=0
$dupebytes=0
for ($i=0;$i -lt ($files.count-1); $i++)
{  
  if ($files[$i].length -ne $files[$i+1].length) {continue}  
  $breakout=$false
  while($true)
  {    
    $sha512 = (get-SHA512 $files[$i].fullname)
    if ($sha512 -ne $null)
    {
      $hashsize+=$files[$i].length
      $hashfiles++
      if (!$hashname.containskey($sha512))
      {        
        $hashname+=@{$sha512=@($files[$i].fullname)}
      }
      else
      {
        $hashname[$sha512]+=$files[$i].fullname
      }
    }
    if ($breakout -eq $true) {break}  
    $i++    
    if ($i -eq ($files.count-1)) {$breakout=$true; continue}
    $breakout=(($files[$i+1].length -ne $files[$i].length ))    
  } 
  foreach ($k in $hashname.keys)
  {
    if ($hashname[$k].count -gt 1)
    {
      write-host ("Duplicates - ({0:N0} Bytes each, {1:N0} matches, {2:N0} Bytes total)):" -f $files[$i].length , $hashname[$k].count, ($files[$i].length*$hashname[$k].count)) -f red
      $hashname[$k]
      $dupebytes+=$hashname[$k].count*$files[$i].length 
      if ($args3 -eq "/delete") {$hashname[$k]|%{del $_ -confirm}}
      $m+=$hashname[$k].count
    }
  }
  $hashname=@{}
} 


""
write-host "Number of Files checked: $($files.count)."
write-host "Number of duplicate files: $m."
Write-host "$($hashfiles) files hashed."
Write-Host "$($hashsize) bytes hashed."
write-host "$dupebytes duplicates bytes."
""
write-host "Time to run: $(([datetime]::now)-$starttime|select hours, minutes, seconds, milliseconds)"
""

