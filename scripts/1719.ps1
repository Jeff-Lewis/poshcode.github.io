## This is a VERY EARLY prototype of a function that could retrieve cmdlet help from TechNet ...
## and hypothetically, other online help sites which used the same format (none)


# REQUIRES the HttpRest module, to convert XHTML to XML (Uses Get-WebPageContent below)
# Otherwise I'm getting 503 errors when trying to resolve the DTD (need to look into that
param(
   [Parameter(Mandatory=$true,Position=0)]
   [String]$Name
,
   [Parameter(Mandatory=$false,Position=1)]
   [String[]]$Sections= @("Name", "Synopsis", "Syntax", "Description")
)


# http://poshcode.org/1718
function Select-Expand {
<# 
.Synopsis
   Like Select-Object -Expand, but with recursive iteration of a select chain
.Description
   Takes a dot-separated series of properties to expand, and recursively iterates the output of each property ...
.Parameter Property
   A collection of property names to expand.
   
   Each property can be a dot-separated series of properties, and each one is expanded, iterated, and then evaluated against the next
.Parameter InputObject
   The input to be selected from
.Parameter Unique
   If set, this becomes a pipeline hold-up, and the total output is checked to ensure uniqueness
.Parameter EmptyToo
   If set, Select-Expand will include empty/null values in it's output
.Example
   Get-Help Get-Command | Select-Expand relatedLinks.navigationLink.uri -Unique

   This will return the online-help link for Get-Command.  It's the equivalent of running the following command:

   C:\PS> Get-Help Get-Command | Select-Object -Expand relatedLinks | Select-Object -Expand navigationLink | Select-Object -Expand uri | Where-Object {$_} | Select-Object -Unique
#>
param(
   [Parameter(ValueFromPipeline=$false,Position=0)]
   [string[]]$Property
,
   [Parameter(ValueFromPipeline=$true)]
   [Alias("IO")]
   [PSObject[]]$InputObject
,
   [Switch]$Unique
,
   [Switch]$EmptyToo
)
begin { 
   if($unique) {
      $output = @()
   }
}
process {
   foreach($io in $InputObject) {
      foreach($prop in $Property -split "\.") {
         if($io -ne $null) {
            $io = $io | Select-Object -Expand $prop
            Write-Verbose $($io | out-string)
         }
      }
      if(!$EmptyToo -and ($io -ne $null)) {
         $io = $io | Where-Object {$_}
      }
      if($unique) {
         $output += @($io)
      } 
      else {
         Write-Output $io
      }
   }
}
end {
   if($unique) {
      Write-Output $output | Select-Object -Unique
   }
}
}
# New-Alias slep Select-Expand

function Get-OnlineHelpContent {
param(
   [Parameter(Mandatory=$true,Position=0)]
   [String]$Name
,
   [Parameter(Mandatory=$false,Position=1)]
   [String[]]$Sections= @("Name", "Synopsis", "Syntax", "Description")
)
process { 
   $uri = Get-Help $Name | Select-Expand relatedLinks.navigationLink.uri -Unique 
   
   if(!$uri) { throw "Couldn't find online help URL for $Name" }
   
   $req = [System.Net.HttpWebRequest]::Create($uri)
   $req.Method = "HEAD"
   $response = $req.GetResponse()
   $uri = $response.ResponseUri.AbsoluteUri + "(pull)"
   $response.Close() # clean up like a good boy
   write-verbose "Fetching: $uri"

   # LEST THERE BE ANY DOUBT: THIS uses HttpRest to convert XHTML to XML
   $global:OnlineHelpContent = Get-WebPageContent $uri "//*[local-name()='div' and @class='ContentArea']"
   # Name, Synopsis, Syntax, Description, 
   
   $NameNode = $global:OnlineHelpContent.SelectSingleNode("//*[local-name()='div' and @class='topic']/*[local-name()='div' and @class='title']")
   $NameNode.SetAttribute("header","NAME")
   
   $global:OnlineHelpContent = $global:OnlineHelpContent.SelectSingleNode("//*[local-name()='div' and @id='mainBody']")
   
   $Synopsis = $global:OnlineHelpContent.SelectSingleNode("*[local-name()='p']")
   $Synopsis.SetAttribute("header","SYNOPSIS")
   
   $headers = $OnlineHelpContent.h2  | ForEach-Object { $_.InnerText().Trim() }
   $content = $OnlineHelpContent.div | ForEach-Object { $_ }

   $global:help = @{Name=$NameNode; Synopsis=$Synopsis}
   if($headers.Count -ne $content.Count) { 
      Write-Warning "Unmatched content"
      foreach($header in $headers) {
        $help.$header = $OnlineHelpContent.SelectNodes( "//*[preceding-sibling::*[1][local-name()='h2' and normalize-space()='$header']]" )
        $help.$header.SetAttribute("header",$header.ToUpper())
      }
   }
   else {
      for($h=0;$h -lt $headers.Count; $h++){
         $help.($headers[$h]) = $content[$h]
         $help.($headers[$h]).SetAttribute("header",$headers[$h].ToUpper())
      }
   }
   $help
   
   $content[$Sections] | ForEach-Object { 
      Write-Output
      Write-Output $_.Header
      Write-Output
      Write-Output ($_.InnerText() -replace '^[\n\s]*\n|\n\s+$')
   }
}
}

Get-OnlineHelpContent $Name | out-null


$help[$Sections] | ForEach-Object { 
   Write-Host
   Write-Host $_.Header -Fore Cyan
   Write-Host
   Write-Host ($_.InnerText() -replace '^[\n\s]*\n|\n\s+$')
}
