# get-mystattype.ps1	: Proxy cmdlet for the Get-StatType cmdlet.
# The scripts add the parameter -ShowInstances to the cmdlet
# Parameters:
#	ShowInstances	: switch to define if all the instances for each metric will be shown
# Author:	LucD
# History:
#	v1.0 27/08/09	first version
#

[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [ValidateNotNullOrEmpty()]
    [System.String[]]
    ${Name},

    [Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [VMware.VimAutomation.Types.InventoryItem[]]
    ${Entity},

    [System.DateTime]
    ${Start},

    [System.DateTime]
    ${Finish},

    [ValidateNotNullOrEmpty()]
    [VMware.VimAutomation.Types.StatInterval[]]
    ${Interval},

    [ValidateNotNullOrEmpty()]
    [VMware.VimAutomation.Types.VIServer[]]
    ${Server},

	[switch]
	${ShowInstances})

begin
{
    try {
        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }
        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Get-StatType', [System.Management.Automation.CommandTypes]::Cmdlet)
        if ($ShowInstances)
        {
			$perfMgr = Get-View (Get-View ServiceInstance).content.perfManager
			
			$PCLookup = @{}
			$perfMgr.PerfCounter | %{$PCLookup[$_.GroupInfo.Key + "." + $_.NameInfo.Key + "." + $_.RollupType]=$_.Key}

			$InstLookup = @{}
			$perfMgr.QueryAvailablePerfMetric(($entity | Get-View).MoRef,$null,$null,$null) | %{
				if($_.Instance -eq ""){
					$InstLookup[$_.CounterId] += @('""')
				}
				else{
					$InstLookup[$_.CounterId] += @($_.Instance)
				}
			}
			
            [Void]$PSBoundParameters.Remove("ShowInstances")
            $scriptCmd = {& $wrappedCmd @PSBoundParameters | %{
				if($InstLookup.ContainsKey($PCLookup[$_])){
					$t = New-Object PSObject
					$t | Add-Member -MemberType NoteProperty -Name Metric -Value $_
					$t | Add-Member -MemberType NoteProperty -Name Instances -Value ($InstLookup[$PCLookup[$_]])
# Output the new object
					$t
# Get rid of metric so identical return values from original Get-StatType wont produce output
					$InstLookup.Remove($PCLookup[$_])
				}
			}}
        }
		else{
            $scriptCmd = {& $wrappedCmd @PSBoundParameters }
        }
        $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
        $steppablePipeline.Begin($PSCmdlet)
    } catch {
        throw
    }
}

process
{
    try {
			$steppablePipeline.Process($_)
		}
    catch {
        Throw
    }
}

end
{
    try {
        $steppablePipeline.End()
    } catch {
        throw
    }
}

