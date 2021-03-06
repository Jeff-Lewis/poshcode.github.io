##############################################################################
##
## Get-ProcessProfile
##
##############################################################################

<#

.SYNOPSIS

Uses cdb.exe from the Debugging Tools for Windows to create a sample-based
profile of .NET or native applications.

.EXAMPLE

$frames = C:\temp\Get-ProcessProfile.ps1 -ProcessId 11844
$frames | % { $_[0] } | group | sort Count | Select Count,Name | ft -auto

Runs a sampling profile on process ID 1184. Then, it extracts out the top
(current) stack entry from each call frame and groups it by the resulting
text.

This gives a report like the following, which was taken while PowerShell
version 2 was slowly enumerating a network share. The output below
demonstrates that PowerShell was spending the majority of its time invoking a
pipeline, and calling the .NET System.IO.FillAttributeInfo API:

Count Name
----- ----
    1 System.Collections.Specialized.HybridDictionary.set_Item(System.Object...
    1 System.Text.StringBuilder..ctor(System.String, Int32, Int32, Int32)
    1 System.Management.Automation.Provider.CmdletProvider.WrapOutputInPSObj...
    1 System.Management.Automation.Provider.NavigationCmdletProvider.GetPare...
    1 System.Management.Automation.Provider.CmdletProvider.get_Force()
    1 System.Management.Automation.Cmdlet.WriteObject(System.Object)
    1 System.String.AppendInPlace(Char[], Int32, Int32, Int32)
    1 Microsoft.PowerShell.ConsoleHostRawUserInterface.LengthInBufferCells(C...
    1 System.Security.Util.StringExpressionSet.CanonicalizePath(System.Strin...
    1 Microsoft.PowerShell.ConsoleControl.GetConsoleScreenBufferInfo(Microso...
    1 System.IO.DirectoryInfo..ctor(System.String, Boolean)
    1 System.Security.Permissions.FileIOPermission.AddPathList(System.Securi...
    2 System.IO.Path.InternalCombine(System.String, System.String)
    2 System.Runtime.InteropServices.SafeHandle.Dispose(Boolean)
   18 System.IO.Directory.InternalGetFileDirectoryNames(System.String, Syste...
   66 System.IO.File.FillAttributeInfo(System.String, WIN32_FILE_ATTRIBUTE_D...
  100 System.Management.Automation.Runspaces.PipelineBase.Invoke(System.Coll...

#>


param(
    ## The process ID to attach to
    [Parameter(Mandatory = $true)]
    $ProcessId,

    ## How many samples to retrieve
    $SampleCount = 100,

    ## Switch parameter to debug a native process
    [Switch] $UseNativeDebugging,

    ## Path to CDB. Will be detected if not supplied.
    $CdbPath
)

## If the user didn't specify a path to CDB, see if we can find it in the
## standard locations.
if(-not $CdbPath)
{
    $cdbPaths = "C:\Program Files (x86)\Windows Kits\8.0\Debuggers\x64\cdb.exe",
        "C:\Program Files (x86)\Windows Kits\8.0\Debuggers\x86\cdb.exe",
        "C:\Program Files\Debugging Tools for Windows (x64)\cdb.exe",
        "C:\Program Files\Debugging Tools for Windows (x86)\cdb.exe"
        
    foreach($path in $CdbPaths)
    {
        if(Test-Path $path)
        {
            ## If we found it, remember it and break.
            $CdbPath = $path
            break
        }
    }

    if(-not $CdbPath)
    {
        throw "Could not find cdb.exe from the Debugging Tools for Windows package"
    }
}

if(-not (Get-Process -Id $ProcessId))
{
    throw "Could not find process ID $ProcessId"
}

## Prepare the command we will send to cdb.exe. We use one command for
## managed applications, and another for native.
$debuggingCommand = ""
$managedDebuggingCommand = ".loadby sos mscorwks; .loadby sos clr; ~*e !CLRStack"
$nativeDebuggingCommand = "~*k"

if($UseNativeDebugging)
{
    $debuggingCommand = $nativeDebuggingCommand
}
else
{
    $debuggingCommand = $managedDebuggingCommand
}

## Create the info to start cdb.exe, redirecting its standard input and output
## so that we can automate it.
$startInfo = [System.Diagnostics.ProcessStartInfo] @{
    FileName = $CdbPath;
    Arguments = "-p $processId -noinh -c `"$debuggingCommand`"";
    UseShellExecute = $false;
    RedirectStandardInput = $true
    RedirectStandardOutput = $true
}

$frames = @()

## Start sampling the process by launching cdb.exe, taking the stack trace,
## and detaching.
1..$SampleCount | % {
    $process = [System.Diagnostics.Process]::Start($startInfo)
    $process.StandardInput.WriteLine("qd")
    $process.StandardInput.Close()
    $r = $process.StandardOutput.ReadToEnd() -split "`n"

    ## Go through the output data, extracting the actual stack trace text
    ## data.
    $frame = @()
    $capture = $false
    switch -regex ($r)
    {
        'Child SP|Child-SP' { $capture = $true; continue; }
        'OS Thread Id|^\s*$' { $capture = $false; if($frame) { $frames += ,$frame; $frame = @() } }
        { $capture -and ($_ -match '\)$|!') } { $frame += $_ -replace ".*? .*? ([^+]*).*",'$1' }
    }

    if($frame) { $frames += ,$frame }

    ## Sleep a little bit (with randomness) so that we get accurate
    ## samples
    Start-Sleep -m (100 + (Get-Random 100))
}

## Output the frames we retrieved.
,$frames
