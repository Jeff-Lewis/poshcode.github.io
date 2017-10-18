<#
.SYNOPSIS
Converts Microsoft Office 365 Best Practices Analyzer HTML reports to CSV.

.DESCRIPTION 
Converts Microsoft Office 365 Best Practices Analyzer HTML reports to CSV.

.PARAMETER FileLocation
Provide the path to one or many HTML files.

.EXAMPLE 
 ConvertExBPATo-CSV -FileLocation (Get-ChildItem *.html)


.NOTES
Author: Josh Wortz
Date Created: 3/3/2015

#>
param(
    [ValidateScript({%{Test-Path $_ -PathType 'Leaf'}})][string[]]$FileLocation

)

function ParseBPA([ValidateScript({%{Test-Path $_ -PathType 'Leaf'}})][string[]]$Files)
{
    
    $detailsRegx = "<div[^>]*>(.*?)<br \/><br \/>"
    $notesRegx = "<img src[^>]*\/>(.*?)<br \/>"

    [array]$HTMLArray = ([string](Get-Content $Files)).replace("<div", "`n<div") -split "`n" 

    #[array]$htmlarray = $newHTML -split "`n"
    [array]$report = $null


    foreach ($line in $htmlarray)
    {
        if ($line -match "<div onclick")
            {
                 [string]$note =([regex]::match($line, $notesregx).Groups[1].Value)
                $Object = New-Object PSObject
                
                $Object | add-member Noteproperty Title $note
                
                if ($line -match "img_Warning")
                    {
                        $type= "Warning"
                    }
                    elseif ($line -match "img_Error")
                    {
                        $type = "Error"
                    }
                    elseif ($line -match "img_Info")
                    {
                        $type = "Informational"
                    }
                    else
                    {
                        $type = "Passed"
                    }
                    
                
                $Object | add-member Noteproperty ErrorType $type
            
            }
        elseif($line -match "hidden_Section" -and !($line -match "<?xml version="))
            {
                [string]$note = ([regex]::match($line, $detailsRegx).Groups[1].Value)  
                $Object | add-member Noteproperty Details $note
                
                $report += $object
            }


    }
    $report

}


Get-ChildItem $FileLocation | %{ParseBPA -Files $_ | export-csv -NoTypeInformation "$_.csv"}
