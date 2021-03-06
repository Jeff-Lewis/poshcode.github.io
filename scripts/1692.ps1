
function Get-FtpList {
#.Synopsis
#  Read a list of files (and directories) from FTP
#.Description
#  An initial implementation of a string-parsing lister for FTP which converts lists to objects (in the one format that I've seen -- there are other formats)
#
#  This implementation will use whatever proxy is set up in the "Internet Options" proxy settings (usually your web proxy, and basically never an FTP server with USER@HOST settings), which may affect the file list format.
#.Parameter Path
#  The full path to the directory you want a listing from, in the form: ftp://servername/folder/
#.Parameter Credentials
#  The login credentials for the ftp server, if needed
#.Example
# $List = Get-FtpList "ftp://joelbennett.net/" (Get-Credential)
# C:\PS>$list | ft Name, Type, Length, LastWriteTime, FullName -auto
#
# Name       Type      Length LastWriteTime         FullName                                                      
# ----       ----      ------ -------------         --------                                                      
# DeskOps    Directory        5/24/2009 12:00:00 AM ftp://joelbennett.net/DeskOps/                
# GeoShell   Directory        5/24/2009 12:00:00 AM ftp://joelbennett.net/GeoShell/               
# Jaykul.asc File      1626   5/24/2009 12:00:00 AM ftp://joelbennett.net/Jaykul.asc              
# ShotGlass  Directory        5/24/2009 12:00:00 AM ftp://joelbennett.net/ShotGlass/              
# images     Directory        2/6/2010 2:13:00 PM   ftp://joelbennett.net/images/    
# index.php  File      407    5/9/2009 12:00:00 AM  ftp://joelbennett.net/index.php               
#
# Description
# -----------
# The first command gets a list of files, directories (and symlinks, if there are any) into $List 
# The second command outputs that list in a useable table format, because the Huddled.FtpItemInfo type hasn't been set up in my Format ps1xml files so by default the output will be in list form.
#
#.Notes
#  This will use a proxy, but only if it's set up correctly in "Internet Options" proxy settings.
#.Link 
# The FTP WebRequest class
# *   http://msdn.microsoft.com/en-us/library/system.net.ftpwebrequest.aspx
#.Link
# The FTP Methods enumeration
# *   http://msdn.microsoft.com/en-us/library/system.net.webrequestmethods.ftp.aspx
#
[CmdletBinding()]
Param(
   [Parameter(Mandatory=$true)]
   [string]$Path
,
   [Parameter(Mandatory=$false)]
   [System.Net.ICredentials]$Credential
)
   
   [System.Net.FtpWebRequest]$request = [System.Net.WebRequest]::Create($path)
   $request.Method = [System.Net.WebRequestMethods+FTP]::ListDirectoryDetails
   if($credential) { $request.Credentials = $credential }
   $response = $request.GetResponse()
   
   if( $response.StatusCode -ne "CommandOK" ) {
      throw "Response Status: $($response.StatusDescription)"
   }
   
   $global:ftpOutputCache = (Receive-Stream $response.GetResponseStream())
   $list = $global:ftpOutputCache -replace "(?:.|\n)*<PRE>\s+((?:.*|\n)+)\s+</PRE>(?:.|\n)*",'$1' -split "`n"
   $( foreach($line in $list | ? { $_ }) {
      [DateTime]$date, [string]$length, [string]$url, [string]$name, $null = $line -split ' + | <A HREF="|">|</A>'
      
      New-Object PSObject -Property @{ 
         LastWriteTime = $date
         FullName      = $path.trim().trim('/') + '/' + $url
         Length        = $(if($length -eq (($length -as [int]) -as [string])) { [int]$length } else { $null })
         Type          = $(if($length -eq (($length -as [int]) -as [string])) { "File" } else { $length })
         Name          = $name
      }
   } # Note: I put a (fake) "Huddled.FtpItemInfo" type name on. You can use that for format.ps1xml
   ) | Sort Type | %{ $_.PSTypeNames.Insert(0, "Huddled.FtpItemInfo"); $_ } | Write-Output  
}



function Receive-Stream {
#.Synopsis
#  Read a stream to the end and close it
#.Description
#  Will read from a byte stream and output a string or a file
#.Param reader
#  The stream to read from
#.Param fileName
#  A file to write to. If this parameter is provided, the function will output to file
#.Param encoding
#  The text encoding, if you want to override the default.
param( [System.IO.Stream]$reader, $fileName, $encoding = [System.Text.Encoding]::GetEncoding( $null ) )
   
   if($fileName) {
      $writer = new-object System.IO.FileStream $fileName, "Create"
   } else {
      [string]$output = ""
   }
       
   [byte[]]$buffer = new-object byte[] 4096
   [int]$total = [int]$count = 0
   do
   {
      $count = $reader.Read($buffer, 0, $buffer.Length)
      if($fileName) {
         $writer.Write($buffer, 0, $count)
      } else {
         $output += $encoding.GetString($buffer, 0, $count)
      }
   } while ($count -gt 0)

   $reader.Close()
   if(!$fileName) { $output }
}

