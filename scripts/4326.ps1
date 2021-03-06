Function Get-VMMemory {
<# 
.SYNOPSIS
Retrieves memory usage percentage for a Windows VMWare virtual server. 
.DESCRIPTION
Often times the memory usage reported by Windows is incorrect on VMWare virtual servers.  This function utilizes the VMWare Performance counters to determin usage percentage.
.PARAMETER ComputerName
Specify a single computer, must be a Virtual server with VMWare Tools installed.
.PARAMETER Delay
The delay, in seconds, between tests
.PARAMETER Count
The number of times to report the memory usage
.EXAMPLE
Get-VMMemory -ComputerName Server1
Gets Memory usage for Server1 with the default 5 count and no delay
.EXAMPLE
Get-VMMemory -ComputerName Server1 -Count 4 -Delay 30
Gets Memory usage for Server1 4 times with a 30 second delay
.NOTES
NAME: Get-VMMemory
AUTHOR: Cody Dean
WEBSITE: http://www.TechJeeper.com
LASTEDIT: 07/19/2013
#>  

    Param(
    [string]$ComputerName = $env:computername,
    [int]$Count = 5,
    [int]$Delay = 0
    )
$ErrorActionPreference = "silentlycontinue"
$server = $ComputerName
$vmMemActive = "\VM Memory\Memory Active in MB"
$vmMemUsed = "\VM Memory\Memory Used in MB"

$used = Get-Counter -ComputerName $server -Counter $vmMemUsed|Foreach-Object {$_.CounterSamples[0].CookedValue}

if ($used)
{
    if ($Delay -gt 2)
    {
        $Delay = $Delay - 2
    }

$totalMem = $used / 1024
$totalMem = "{0:N2}" -f $totalMem
Write-Host "$server - Total Memory (GB): $totalMem"
$x = 0

while ($x -lt $Count)
{
    $x++
    $time = Get-Date -f T
    $active = Get-Counter -ComputerName $server -Counter $vmMemActive|Foreach-Object {$_.CounterSamples[0].CookedValue}
    $used = Get-Counter -ComputerName $server -Counter $vmMemUsed|Foreach-Object {$_.CounterSamples[0].CookedValue}
    $percentage = $active / $used
    $percentage = $percentage * 100
    $percentage = "{0:N0}" -f $percentage

    if ($percentage -ge 80)
    {
        Write-Host "$time - Memory Usage: $percentage%" -ForegroundColor Red
    }
    else
    {
        Write-Host "$time - Memory Usage: $percentage%"
    }
   
}

}
else
{
    Write-Host "ERROR: VMWARE PERFORMANCE COUNTERS NOT FOUND OR HOST COULD NOT BE REACHED" -ForegroundColor Red -BackgroundColor Black
}}
