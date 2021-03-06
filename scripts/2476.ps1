## Requires the Experimental.IO "LongPath" library from the BCL team: http://bcl.codeplex.com/
## Compile it against .Net 3.5 (for PowerShell's sake) and place it the module folder with this psm1
if(!("Microsoft.Experimental.IO.LongPathDirectory" -as [type])) {
   Add-Type -Path $PSScriptRoot\Microsoft.Experimental.IO.dll
}

function Get-LongPath {
[CmdletBinding(DefaultParameterSetName="AllItems")]
param(
   [Parameter(Position=0,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
   [string]$Path = $pwd
, 
   [Parameter(ParameterSetName="DirectoriesOnly")]
   [Alias("od","do")]
   [switch]$DirectoriesOnly
, 
   [Parameter(ParameterSetName="FilesOnly")]
   [Alias("of","fo")]
   [switch]$FilesOnly
,
   [switch]$Recurse
,
   [switch]$Indent
)
begin {
   if($Recurse -and $Indent -and (Test-Path variable:script:pad)) {
      $script:pad += "  "
   } else {
      $script:pad = ""
   }
   $null = $PSBoundParameters.Remove("Path")
   if($PSCmdlet.ParameterSetName -eq "FilesOnly") {
      Write-Verbose $Path
   }
}
process {
   switch($PSCmdlet.ParameterSetName) {
      "FilesOnly" {
         if($Recurse) {
            [Microsoft.Experimental.IO.LongPathDirectory]::EnumerateFileSystemEntries( $Path ) | %{ 
               if( [Microsoft.Experimental.IO.LongPathDirectory]::Exists( $_ ) ) {
                  Get-LongPath $_ @PSBoundParameters
               } else {
                  $script:pad + $_
               }
            }
         } else {
            [Microsoft.Experimental.IO.LongPathDirectory]::EnumerateFiles( $Path )
         }
      }
      "DirectoriesOnly" {
         if($Recurse) {
            [Microsoft.Experimental.IO.LongPathDirectory]::EnumerateDirectories( $Path ) | %{ 
               $script:pad + $_ + "\"
               if($recurse) {
                  Get-LongPath $_ @PSBoundParameters
               }
            }
         } else {
            [Microsoft.Experimental.IO.LongPathDirectory]::EnumerateDirectories( $Path )
         }
      }
      "AllItems" {
         if($recurse) {
            [Microsoft.Experimental.IO.LongPathDirectory]::EnumerateFileSystemEntries( $Path ) | %{ 
               if( [Microsoft.Experimental.IO.LongPathDirectory]::Exists( $_ ) ) {
                  $script:pad + $_ + "\"
                  Get-LongPath $_ @PSBoundParameters
               } else {
                  $script:pad + $_
               }
            }
         } else { 
            [Microsoft.Experimental.IO.LongPathDirectory]::EnumerateFileSystemEntries( $Path )
         }
      }
   }
}
end {
   if($Indent) {
      if($script:pad.Length -gt 0) {
         $script:pad = $script:pad.SubString(0, $script:pad.Length - 2)
      } else {
         remove-item variable:script:pad -EA 0
      }
   }
}
}

