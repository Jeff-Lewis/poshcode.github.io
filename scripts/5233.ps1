#========================================================================
# Created By: Anders Wahlqvist
# Website: DollarUnderscore (http://dollarunderscore.azurewebsites.net)
#========================================================================

function Get-PackageTrace
{
    <#
    .Synopsis
       Retrieves a trace of a package sent with the swedish postal service.
    .DESCRIPTION
       If you give this cmdlet a Package Id it will trace the package through the swedish postal service website and return an object for each step it finds.
    .EXAMPLE
       Get-PackageTrace -Id MyPackageId

    .EXAMPLE
       Get-PackageTrace -Id MyPackageId1, MyPackageId2

    .PARAMETER Id
    The Id or Id's to trace.
    #>

    [CmdletBinding()]
    Param
    (
        # The Id of the package
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [string[]] $Id)

    Begin { }

    Process {

        foreach ($PackId in $Id) {

            $PackageTrace = $null
            $TraceItems = $null

            $PackageTrace = Invoke-WebRequest -Uri "http://www.posten.se/en/Pages/Track-and-trace.aspx?search=$PackId" -UseBasicParsing

            Write-Verbose "Parsing out each event from the package trace (Id: $PackId)"

            $TraceItems = ((($PackageTrace.Content -split "<table class=`"PWP-moduleTable nttEventsTable`"")[1] -split "</TABLE>")[0]) -split "<tr class=" | Select-Object -Skip 2

            if ($TraceItems.Count -eq 0) {
                Write-Warning "No events were found for package with Id $PackId"
                Continue
            }

            foreach ($TraceItem in $TraceItems) {

                $EventDate = $null
                $Location = $null
                $Comment = $null
                $PackageId = $null

                $EventDate = Get-Date (($TraceItem -split "<td>")[1] -split "</td>")[0] -Format "yyyy-MM-dd HH:mm:ss"
                $Location = (($TraceItem -split "<td>")[2] -split "</td>")[0]
                $Comment = (($TraceItem -split "<td>")[3] -split "</td>")[0] -replace "&#180;","´"
                $PackageId = $PackId

                Write-Debug "Properties are parsed."

                $returnObject = New-Object System.Object
                $returnObject | Add-Member -Type NoteProperty -Name EventDate -Value $EventDate
                $returnObject | Add-Member -Type NoteProperty -Name Location -Value $Location
                $returnObject | Add-Member -Type NoteProperty -Name Comment -Value $Comment
                $returnObject | Add-Member -Type NoteProperty -Name Id -Value $PackageId

                Write-Output $returnObject
            }
        }
    }

    End {
        Write-Verbose "Done"
    }
}
