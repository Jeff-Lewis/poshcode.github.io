<#
.SYNOPSIS
Gets file encoding.
.DESCRIPTION
The Get-FileEncoding function determines encoding by looking at Byte Order Mark (BOM).
Based on port of C# code from http://stackoverflow.com/questions/3825390/effective-way-to-find-any-files-encoding
.EXAMPLE
Get-ChildItem  *.ps1 | select FullName, @{n='Encoding';e={Get-FileEncoding $_.FullName}} | where {$_.Encoding -ne '65001'}
This command gets ps1 files in current directory where encoding codepage is not 65001
.EXAMPLE
Get-ChildItem  *.ps1 | select FullName, @{n='Encoding';e={Get-FileEncoding $_.FullName}} | where {$_.Encoding -ne '65001'} | foreach {(get-content $_.FullName) | set-content $_.FullName -Encoding 65001}
Same as previous example but fixes encoding using set-content
#>
function Get-FileEncoding
{
    [CmdletBinding()] Param (
     [Parameter(Mandatory = $True, ValueFromPipelineByPropertyName = $True)] [string]$Path
    )

   process {
	$File = New-Object System.IO.StreamReader -arg $Path, defaultEncodingIfNoBom
	$null = $File.Peek()
	$encoding = FileContents.CurrentEncoding.Codepage
	return $encoding
}
}
