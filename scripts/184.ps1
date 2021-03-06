## Send-Paste.ps1 (aka sprunge for Pastebin)
##############################################################################################################
## Uploads code to any pastebin.com based pastebin site and returns the url for you.
## History:
## v 2.0 - works with "pastebin" (including http://posh.jaykul.com/p/ and http://PowerShellCentral.com/Scripts/)
## v 1.0 - Worked with a special pastebin
##############################################################################################################
#function Send-Paste {
param( 
   $Title, 
   $Description="Automated paste from PowerShell console", 
   $KeepFor="d", 
   $Language="posh", 
   $Author = "Jaykul", # $(Read-Host "Your name"), 
   $url="http://posh.jaykul.com/p/" 
)
   
BEGIN {
   $null = [Reflection.Assembly]::LoadWithPartialName("System.Web")
   [string]$data = $null;
   [string]$meta = $null;

   if($language) {
      $meta = "format=" + [System.Web.HttpUtility]::UrlEncode($language)
      # $url = $url + "?" +$lang
   } else {
      $meta = "format=text"
   }
  
   do {
      switch -regex ($KeepFor) {
         "^d.*" { $meta += "&expiry=d" }
         "^m.*" { $meta += "&expiry=m" }
         "^f.*" { $meta += "&expiry=f" }
         default { 
            $KeepFor = Read-Host "Invalid value for 'KeepFor' parameter. Please specify 'day', 'month', or 'forever'"
         }
      }
   } until ( $meta -like "*&expiry*" )

   if($Description) {
      $meta += "&descrip=" + [System.Web.HttpUtility]::UrlEncode($Description)
   } else {
      $meta += "&descrip="
   }   
   $meta += "&poster=" + [System.Web.HttpUtility]::UrlEncode($Author)
   
   function PasteBin-Text ($meta, $title, $data) {
      $meta += "&paste=Send&posttitle=" + [System.Web.HttpUtility]::UrlEncode($Title)
      $data = $meta + "&code2=" + [System.Web.HttpUtility]::UrlEncode($data)
      
      # Write-Host $data -fore yellow
      
      $request = [System.Net.WebRequest]::Create($url)
      $request.ContentType = "application/x-www-form-urlencoded"
      $request.ContentLength = $data.Length
      $request.Method = "POST"

      $post = new-object IO.StreamWriter $request.GetRequestStream()
      $post.Write($data,0,$data.Length)
      $post.Flush()
      $post.Close()

      # $reader = new-object IO.StreamReader $request.GetResponse().GetResponseStream() ##,[Text.Encoding]::UTF8
      # write-output $reader.ReadToEnd()
      # $reader.Close()
      write-output $request.GetResponse().ResponseUri.AbsoluteUri
      $request.Abort()      
   }
}

PROCESS {
   switch($_) {
      {$_ -is [System.IO.FileInfo]} {
         $Title = $_.Name
         Write-Output $_.FullName
         Write-Output $(PasteBin-Text $meta $Title $([string]::join("`n",(Get-Content $_.FullName))))
      }
      {$_ -is [String]} {
         if(!$data -and !$Title){
            $Title = Read-Host "Give us a title for your post"
         }
         $data += "`n" + $_ 
      }
      ## Todo, handle folders?
      default {
         Write-Error "Unable to process $_"
      }
   }
}
END {
   if($data) { 
      Write-Output $(PasteBin-Text $meta $Title $data)
   }
}
#}
