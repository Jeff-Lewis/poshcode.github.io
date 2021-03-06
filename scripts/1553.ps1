####################################################################################################
## Script Name:     N++CR FuncGuard Module
## Created On:      12/19/2009
## Author:          Thell Fowler
## File:            FuncGuard.psm1
## Usage:           
## Version:         0.0.1
## Purpose:         Provides cmdlets for working with function guards in the N++CR source files:
##                      Add-FuncGuard - Create header and source entries for function guard.
##                      Get-FuncGuard - list available func_guards categories.
##                      Find-FuncGuard - list file and line instances of
##						Update-FuncGuard - update category template headers.
##                      Enable-FuncGuard
##                      Disable-FuncGuard
##                      Remove-FuncGuard - Delete all entries for function guard.
##
## Requirements:    PowerShell Version 2
## Last Updated:    12/19/2009
## History:
##                  0.0.1  12/19/2009 - Initial rendition.
##
####################################################################################################
#requires -version 2.0
Set-StrictMode -Version 2

# The export function is obtained from example 7 in Export-FunctionMember
function export {
    param (
        [parameter(mandatory=$true)] [validateset("function","variable")] $type,
        [parameter(mandatory=$true)] $name,
        [parameter(mandatory=$true)] $value
    )
	if ( $args -ne "PSUnit" ) {
		if ($type -eq "function")
		{
			Set-item "function:script:$name" $value
			Export-ModuleMember $name
		}
		else
		{
			Set-Variable -scope Script $name $value
			Export-ModuleMember -variable $name
		}
	}
}

export function Add-FuncGuard {
	<#
	.SYNOPSIS
		Modifies the target C++ source code for a new function guard.
	.DESCRIPTION
		Function guards are a N++CR debug tool created by Jocelyn Legault for debug
		function tracing.  Add-FuncGuard generates the required source code lines to
		for function guard definition, enable/disable control, and importing.
	.EXAMPLE
		PS C:\NPPCR_ROOT>Add-FuncGuard -prefix "NPPCR" -path "$NPPCR_ROOT\PowerEditor\src\MISC\Debug\" `
		>> -name "WinMain" `
		>> -description "Trace functions in WinMain.cpp, should not be used in other files."
	
		Results in the following code being added:
			... to FuncGuards_skel.h and FuncGuards.h (if it exists):
				// func_guard(guard_WinMain);
				// Description:  Trace functions in WinMain.cpp, should not be used in other files.
				// #define NPPCR_GUARD_WINMAIN
	
			... to FuncGuards.cpp:
				#ifdef NPPCR_GUARD_WINMAIN
					func_guard_enable_cat(guard_WinMain);
				#else
					func_guard_disable_cat(guard_WinMain);
				#endif
	
			... to FuncGuardsImport.h
				func_guard_import_cat(guard_WinMain);
	
	.PARAMETER Prefix
		An all upper case string prefixing the preprocessor MACRO value.
	.PARAMETER Path
		Path to th function guard source files directory.
	.PARAMETER Name
		CamelCase_UnderscoreSpaced name of the function guard category.
	.PARAMETER Description
		Category notes inserted as comments to FuncGuards_skel.h && FuncGuards.h
	#>
	[CmdletBinding()]
	param(
		[Parameter(Position=0, Mandatory=$true)]
		[string]
		$Prefix = $(Throw 'Preprocessor MACRO prefix is required.')
	,
		[Parameter(Position=1, Mandatory=$true)]
		[string]
		$Path = $(Throw 'Path to required function guard source files is required.')
	,
		[Parameter(Position=2, Mandatory=$true)]
		[string]
		$Name = $(Throw 'CamelCase_UnderscoreSpaced function guard name is required.')
	,
		[Parameter(Position=3, Mandatory=$false)]
		[string]
		$Description
	)
	BEGIN {
		# Parameter Validation
		try {
			Test-PrefixParameter -Prefix $Prefix
			Test-PathParameter -Path $Path
			Test-NameParameter -Name $Name
			Get-SourceFiles -sourceType "all" -Path $Path
		}
		catch {
			Format-ErrorRecord $_ | Write-Debug
			throw $_
		}
	}
	PROCESS {
		# Check for pre-existence of $Name in function guard files.
		
		# Insert function guard statements into source files.
	}
	END {
		# Report was done.
		
		# Clean-up
		
		return $true
	}
}

function Test-PrefixParameter {
	param([string]$Prefix)
}
function Test-PathParameter {
	param([string]$Path)
	if (! (Test-Path -Path $Path -PathType Container) ) {
		throw (New-Object IO.DirectoryNotFoundException $Path);
	}
}
function Test-NameParameter {
	param([string]$Name)
	$retVal=$false
	
	if (! ( $Name -cmatch "(\p{Lu}{1}\p{Ll}+)+($|_((\p{Lu}{1}\p{Ll}+)|\d)+|\d+)+" ) ) {
		throw (New-Object System.FormatException "Invalid function guard name format.")
	}
	
	return $true
}

function Get-SourceFiles {
	param([string]$sourceType,[string]$Path)
	$SourceFiles = @{}

	if ( ( $sourceType -eq "all" ) -or ( $sourceType -eq "required" ) ) {
		$SourceFiles = (Get-RequiredFiles $Path)
	}
	return $SourceFiles
}

function Get-RequiredFiles {
	param([string]$Path)
	$RequiredSourceFiles = @{}

	$TestFiles = @{
		"SkeletonHeader" = (Join-Path -Path $Path -ChildPath "FuncGuards_skel.h");
		"GuardSource" = (Join-Path -Path $Path -ChildPath "FuncGuards.cpp");
		"GuardImport" = (Join-Path -Path $Path -ChildPath "FuncGuardsImport.h")
	}
	
	$TestFiles.keys | foreach {
		if (Test-Path -Path $TestFiles.$_ -PathType leaf) {
			$RequiredSourceFiles.add("$_", (Get-Item $TestFiles.$_ ))
		} else {
			throw (New-Object IO.FileNotFoundException $TestFiles.$_)
		}
	}

	$TestFiles = $null
	
	return $RequiredSourceFiles
}

