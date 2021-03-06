New-Alias see Get-CommandDefinition

#.SYNOPSIS
#  Gets the definition of the first command found
#.LINK
#  Get-Command
#.NOTES
#  PowerShell lazy loads modules so this wont display anything if you specify a wildcard and the module hasn't been loaded yet.
#  To work around it either load the module first or use a literal name.
#
#  PowerShell lets you type "Whatever" as a shortcut for "Get-Whatever" but these aren't real aliases.
#  So -Name Whatever wont work. You either have to manually create a real alias or use -Name Get-Whatever
function Get-CommandDefinition {
	[OutputType([string])]
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true, Position = 0)]
		[string[]]$Name
,
		[Alias('PSSnapin')]
		[string[]]$Module
,
		[Alias('Type')]
		[System.Management.Automation.CommandTypes]$CommandType
	)

	function qname {
		if ($args[0].Module) { '{0}\{1}' -f $args[0].Module,$args[0].Name } else { $args[0].Name }
	}

	Get-Command @PSBoundParameters | Select-Object -First 1 |%{
		$out = ''
		$a = [System.Collections.Generic.HashSet[string]]([System.StringComparer]::OrdinalIgnoreCase)

		if ($_ -is [System.Management.Automation.AliasInfo]) { $null = $a.Add($_.Name) }

		while ($_ -is [System.Management.Automation.AliasInfo]) {
			if ($a.Add($_.Definition)) {
				$out = "{0}#A: {1} -> {2}`n" -f $out,(qname $_),$_.Definition
			} else {
				$out = "{0}#A: {1} -> {2} ..." -f $out,(qname $_),$_.Definition
				break
			}
			if ($null -ceq $_.ReferencedCommand) { break }
			$_ = $_.ReferencedCommand
		}
		if ($_ -is [System.Management.Automation.CmdletInfo]) {
			if ($null -cne $_.ImplementingType) {
				$out = "{0}# {1}`n#   {2}`n" -f $out,$_.ImplementingType.Module,$_.ImplementingType
			}
		} elseif ($_ -is [System.Management.Automation.FunctionInfo]) {
			$out = "{0}#F: {1}`n" -f $out,(qname $_)
		}
		if ($_ -is [System.Management.Automation.CommandInfo] -and $_ -isnot [System.Management.Automation.AliasInfo]) {
			$out += $_.Definition
		}
		$out
	}
}
