function Split {
<#
.Synopsis
Splits up a file into smaller files.
.Description
This function takes a file as input and splits it into files by a set number of
lines.
.Parameter filename
The name of the file to be used as an input.
This value can be piped to the function (see examples)
.Parameter lines
The number of lines per file.
.Parameter prefix
A prefix for the output filenames.  Defaults to 'split.'
.Parameter extension
The file extension to use for output files.
.Example
# Simple split of a file.
Split -filename mybigfile.txt -lines 100
.Example
# Pass a number of files by pipeline, filtering out directories
ls | ?{-not $_.PSIsContainer} | %{$_.FullName} | Split -lines 100
#>
  param([Parameter(Mandatory=$true,
                   ValueFromPipeLine=$true)]
        [string]$filename,
        [Parameter(Mandatory=$true)]
        [int]$lines,
        [Parameter(Mandatory=$false)]
        [string]$prefix = 'split.',
        [Parameter(Mandatory=$false)]
        [string]$extension = 'txt')
        
  if (-not (Test-Path $file)) {
    Write-Host "$file not found!"
    break
  }
  
  $increment = 0
  $line = 0
  
  Get-Content $file |
    %{
      $line += 1
      
      if (-not ($lines % $line)) {
        $increment += 1
      }
      
      $_ >> "$file.$increment.$extension"
    }  
}
