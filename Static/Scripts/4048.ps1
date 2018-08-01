#######################
<#
.SYNOPSIS
Gets the Scan time information for Sophos
.DESCRIPTION
The Get-SophosScanTime function gets the Sophos weekly scan time information.
.EXAMPLE
Get-SophosScanTime "Z002"
This command gets information for computername Z002.
.EXAMPLE
Get-Content ./servers.txt | Get-SophosScanTime
This command gets information for a list of servers stored in servers.txt.
.EXAMPLE
Get-SophosScanTime (get-content ./servers.txt)
This command gets information for a list of servers stored in servers.txt.
.NOTES 
Version History 
v1.0   - Chad Miller - Initial release 
#>
function Get-SophosScanTime
{
    [CmdletBinding()]
    param(
    [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    [ValidateNotNullorEmpty()]
    [string[]]$ComputerName
    )
    BEGIN {}
    PROCESS {
        foreach ($computer in $computername) {
            Get-WMIObject  -ComputerName $computer -Query "SELECT * FROM CIM_DataFile WHERE Drive ='C:' AND Path='\\ProgramData\\Sophos\\Sophos Anti-Virus\\Logs\\' AND FileName LIKE 'Week%' AND Extension='txt'" | 
            Select CSName,@{n="StartTime";e={($_.ConvertToDateTime($_.creationdate)).ToString("f")}},@{n="EndTime";e={($_.ConvertToDateTime($_.lastmodified)).ToString("f")}},
            @{n="RunDuration";e={(($_.ConvertToDateTime($_.lastmodified)).Subtract(($_.ConvertToDateTime($_.creationdate)))).ToString()}}
            
        }
    }
    END {}
}

