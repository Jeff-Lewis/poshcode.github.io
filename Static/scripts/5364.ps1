Function Set-FolderCompression
{
	Param(
		[Parameter(
			Position=0,
			Mandatory=$true,
			ValueFromPipeline=$true)
		]
		[string]$Path,
		[switch]$Uncompress,
		[switch]$Recurse
	)

	$target_folder = $Path.TrimEnd(92) | gi -Force -ErrorAction 'Stop'

	if (($target_folder.Attributes -band 0x10) -ne 0x10)
	{
		throw 'The path must be a valid directory'
	}

	if ($Uncompress) { $un = 'un'} else { $un = '' }

	filter DoIt
	{
		Invoke-Expression -Command `
			"-not (Invoke-WmiMethod -Path `"\\.\root\cimv2:Win32_Directory.Name='$_'`" -Name $($un)compress).ReturnValue"
	}

	if ($Recurse)
	{
		$target_folder `
			| Get-ChildItem -Force -Directory -Recurse `
			| ForEach-Object -Process { $_.FullName | DoIt | Out-Null }
	}
	$target_folder.FullName | DoIt | Out-Default
}
Set-Alias -Name 'press' -Value 'Set-FolderCompression'

