## Get-WebFile.ps1 (aka wget for PowerShell)
##############################################################################################################
## Downloads a file or page from the web
## History:
## v3.5 - Add -Quiet switch to turn off the progress reports ...
## v3.4 - Add progress report for files which don't report size
## v3.3 - Add progress report for files which report their size
## v3.2 - Use the pure Stream object because StreamWriter is based on TextWriter:
##        it was messing up binary files, and making mistakes with extended characters in text
## v3.1 - Unwrap the filename when it has quotes around it
## v3   - rewritten completely using HttpWebRequest + HttpWebResponse to figure out the file name, if possible
## v2   - adds a ton of parsing to make the output pretty
##        added measuring the scripts involved in the command, (uses Tokenizer)
##############################################################################################################
#function wget {
   param( 
      $url = (Read-Host "The URL to download"),
      $fileName, 
      [switch]$quiet
   )
   
   $req = [System.Net.HttpWebRequest]::Create($url);
   $res = $req.GetResponse();

   if($fileName -and !(Split-Path $fileName)) {
      $fileName = Join-Path (Get-Location -PSProvider "FileSystem") $fileName
   } 
   elseif(($fileName -eq $null) -or (Test-Path -PathType "Container" $fileName))
   {
#  if( -and !((Test-Path -PathType "Leaf" $fileName) -or ((Test-Path -PathType "Container" (Split-Path $fileName)) -and -not )))
      [string]$fileName = ([regex]'(?i)filename=(.*)$').Match( $res.Headers["Content-Disposition"] ).Groups[1].Value
      $fileName = $fileName.trim("\/""'")
      if(!$fileName) {
         $fileName = $res.ResponseUri.Segments[-1]
         $fileName = $fileName.trim("\/")
         if(!$fileName) { 
            $fileName = Read-Host "Please provide a file name"
         }
         $fileName = $fileName.trim("\/")
         if(!([IO.FileInfo]$fileName).Extension) {
            $fileName = $fileName + "." + $res.ContentType.Split(";")[0].Split("/")[1]
         }
      }
      $fileName = Join-Path (Get-Location -PSProvider "FileSystem") $fileName
   }

   if($res.StatusCode -eq 200) {
      [int]$goal = $res.ContentLength
      $reader = $res.GetResponseStream()
      $writer = new-object System.IO.FileStream $fileName, "Create"
      [byte[]]$buffer = new-object byte[] 4096
      [int]$total = [int]$count = 0
      do
      {
         $count = $reader.Read($buffer, 0, $buffer.Length);
         $writer.Write($buffer, 0, $count);
         if(!$quiet) {
            $total += $count
            if($goal -gt 0) {
               Write-Progress "Downloading $url" "Saving $total of $goal" -id 0 -percentComplete (($total/$goal)*100)
            } else {
               Write-Progress "Downloading $url" "Saving $total bytes..." -id 0
            }
         }
      } while ($count -gt 0)
      
      $writer.Flush()
      $reader.Close()
      $writer.Close()
   }
   $res.Close(); 
   ls $fileName
#}
