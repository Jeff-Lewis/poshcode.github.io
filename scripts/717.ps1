# Author: Steven Murawski http://www.mindofroot.com

# This script creates two functions (and a helper function).  One starts logging all commands entered,
# and the second removes the logging.
# This script is similar to the Start-Transcript, but only logs the command line and not the output.

# Modified to add the logging at the beginning of the Prompt function, otherwise it appeared to 
# impact some functions display options.  I also added some verification to see that the log directory
# exists and to create it if not.
# The format operator doesn't like scriptblocks in the string it is doing the replacement into
# .. should be the last for a while.


function New-ScriptBlock()
{
	param ([string]$scriptblock)
	$executioncontext.InvokeCommand.NewScriptBlock($scriptblock.trim())
}

function Start-Verify ()
{
	param ($logfile = 'c:\scripts\powershell\logs\verify.txt')

	#if the log folder does not exist, create one
	if (-not (test-path (split-path $logfile)))
	{
		mkdir (Split-Path $logfile) | Out-Null
	}

	$lastcmd = 'get-history | select -Last 1 | Foreach-Object { $_.CommandLine.ToString() } | Out-File -Append ' + $logfile
	Get-Content -Path function:\prompt | ForEach-Object { $function:prompt =  New-ScriptBlock ("$lastcmd;`n" + $_.toString()) } | Out-Null
}

function Stop-Verify ()
{
	$lastcmd = '^get-history.*;' 
	Get-Content -Path function:\prompt | ForEach-Object { $function:prompt = New-ScriptBlock ($_.tostring() -replace "$lastcmd")} | Out-Null
}
