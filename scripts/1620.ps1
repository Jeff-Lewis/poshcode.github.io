<#
.SYNOPSIS
	PurgeFiles - recursively remove files with given extension and maximum age from a given path.
.DESCRIPTION
	Read the synopsis
	Example
		PurgeFiles.psq -path C:\temp -ext .tmp -max 24
.EXAMPLE
	PurgeFiles.psq -path C:\temp -ext .tmp -max 24
#>
# HISTORY
# 2010/01/29
# rluiten	Created

param(
	 [Parameter(Mandatory=$true)][string] $path
	,[Parameter(Mandatory=$true)][string] $extension
	,[Parameter(Mandatory=$true)][int] $maxHours
	,[switch] $deleteMode = $false
	,[switch] $listMode = $false
)

function delete-file([string]$path, [string]$extension, [datetime]$oldestAllowed, [bool] $deleteMode, [bool] $listMode)
{
	$filesToRemove = Get-Childitem $path -recurse |
		?{	!$_.PSIsContainer -and
			($_.LastWriteTime -lt $oldestAllowed) -and
			($_.Extension -eq $extension)
		}
	if ($listMode -and $filesToRemove) {
		$filesToRemove | %{write-host "FILE: $($_.LastWriteTime) ""$($_.FullName)""`r`n"}
	}
	if ($deleteMode -and $filesToRemove) {
		write-host "Removing Files...`r`n"
		$filesToRemove | remove-item -force
	}
}

$oldestAllowed = (get-date).AddHours(-$maxHours)

if (-not $deleteMode) {
	write-host "Running in trial mode, no files will be deleted.`r`n"
}
delete-file $path $extension $oldestAllowed $deleteMode $listMode

