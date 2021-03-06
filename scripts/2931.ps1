# This requires  JSON 1.7 ( http://poshcode.org/2930 ) and the HttpRest ( http://poshcode.org/2097 ) modules
# It's a first draft at Paraimpu cmdlets 
# I'm not sure yet that using Paraimpu with my Chumby gets me what I want, since it only shows one item and can't go back to old ones.
#
# YOU SHOULD SET THE $Token DEFAULT VALUES TO YOUR "Thing"'s Token!

ipmo json, httprest

function Send-Paraimpu {
#.Synopsis 
#  Send data to paraimpu!
#.Description
#  Send JSON data to Paraimpu (don't forget JSON is case sensitive)
#.Example
#  Send-Paraimpu @{ 
#     text  = "This is a test message for my chumby, so I'm sending an image and sound too!"
#     image = "http://www.blogsdna.com/wp-content/uploads/2009/12/PowerShell-Logo.png"
#     sound = "http://www.frogstar.com/audio/download/14250/gong.mp3"
#  }
#.Notes 
#  Remember javascript is case sensitive!
param(
   # The data you want to send to Paraimpu
   [Hashtable]$Data, 
   # The token of the paraimpu "Generic Sensor" to send the data to
   [Guid]$Token = "a9988bbd-cb35-4b2d-ba23-69198d36977b"
)
   $json = New-JSON @{
      token = $Token
      'content-type' = "application/json"
      data = $Data
   }
   http post http://paraimpu.crs4.it/data/new -content $json
}

function Send-ParaChumby { 
#.Synopsis 
#  Send data to paraimpu with an image and sound for Chumby
#.Description
#  Send JSON data to Paraimpu ...
#.Example
#  Send-Paraimpu "This is a test message for my chumby, and has default image and sound."
param(
   [Parameter(Position=0,ValueFromPipeline=$true,Mandatory=$true)]
   $InputObject,
   [Parameter(Position=1)]
   $Image, 
   [Parameter(Position=2)]
   $Sound = "http://www.frogstar.com/audio/download/14250/gong.mp3",
   [Switch]$Collect,
   [Int]$Width = 30,
   [Guid]$Token = "a9988bbd-cb35-4b2d-ba23-69198d36977b"
)
begin {
   if($Collect) {
      $output = New-Object System.Collections.ArrayList
   }
}
process {
   if(!$Collect) {
      Send-Paraimpu @{ text = ($InputObject | Out-String -Width $Width | Tee -var dbug) -replace "`r`n","`n"; image = $Image; sound = $Sound } -Token:$Token
      Write-Verbose $dbug
   } else {
      $null = $Output.Add($InputObject)
   }
}
end {
   if($Collect) {
      Send-Paraimpu @{ text = ($Output | Out-String -Width $Width | Tee -var dbug) -replace "`r`n","`n"; image = $Image; sound = $Sound } -Token:$Token
      Write-Verbose $dbug
   }
}}


