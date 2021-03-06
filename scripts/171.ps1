## New-Script function
## Creates a new script from the most recent commands in history
##################################################################################################
## Example Usage:
##    New-Script ScriptName 4
##        creates a script from the most recent four commands 
##    New-Script Clipboard -id 10,11,12,14
##        sends the the specified commands from the history to the clipboard
##    Notepad (New-Script ScriptName 20)
##        sends the most recent twenty commands to the script, and then opens the script in notepad
##################################################################################################
## As a tip, I use a prompt function something like this to get the ID into the prompt:
##
## function prompt {
##   return "`[{0}]: " -f ((get-history -count 1).Id + 1)
## }
##################################################################################################
## Revision History
## 1.0 - initial release
## 1.1 - fix bug with specifying multiple IDs
## 2.0 - use the current folder as the default instead of throwing an exception
##     - prompt to overwrite if not -Force
##################################################################################################

#function New-Script {
param( 
   [string]$script=(Read-Host "A name for your script"),
   [int]$count=1, 
   [int[]]$id=@((Get-History -count 1| Select Id).Id),
   [switch]$Force
)

# if there's only one id, then the count counts, otherwise we just use the ids
if($id.Count -eq 1) { 1..($count-1)|%{ $id += $id[-1]-1 } }
# Get the CommandLines from the history items...
$commands = Get-History -id $id | &{process{ $_.CommandLine }}

if($script -eq "clipboard") {
   if( @(Get-PSSnapin -Name "pscx").Count ) {
      $commands | out-clipboard
   } elseif(@(gcm clip.exe).Count) {
      $commands | clip
   }
} else {
   $folder = Split-Path $script
   if(!$folder) {
      # default to putting it in my "Windows PowerShell\scripts" folder which I have in my path...
      $folder = Join-Path (Split-Path $Profile) "Scripts"
   }
   if(!(Test-Path $folder)) { 
      # if that fails, put it in the current path (on the file system)
      $folder = Get-Location -PSProvider "FileSystem"
   }
   # add the ps1 extension if it's not already there ...
   $file = Join-Path $folder (Split-Path $script -leaf)
   if(!(([IO.FileInfo]$file).Extension)) { 
      $file = "$file.ps1"
   }
   # write an error message if the file already exists, unless -Force
   if((Test-Path $file) -and (!$Force)) {
      Write-Error "The file already exists, do you want to overwrite?"
   }
   # and confirm before setting the content if the file already exists, unless -Force
   $commands | set-content $file -Confirm:((Test-Path $file) -and (!$Force))
   Get-Item $file
}
#}
