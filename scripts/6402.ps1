# requires -version 3.0
Function Show-MyDotNetVersions
{
<#
.Synopsis
   Shows .Net versions
.DESCRIPTION
   Reads from the registry all the .Net versions installed on the local machine and displays them in HTML page 
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>

    $title = "All .Net Versions on the local machine"
    $outputHtml = "$env:Temp\dotnetversions.html"
    $regBase = "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP"
    $rgDotNet20 = "$regBase\v2.0*"
    $rgDotNet30 = "$regBase\v3.0"
    $rgDotNet35 = "$regBase\v3.5"
    $rgDotNet40 = "$regBase\v4.0\Client"
    $rgDotNet45 = "$regBase\v4\Full"

    # .Net 2.0
    if (Test-Path $rgDotNet20) { $dotNet20 = (Get-ItemProperty -Path $rgDotNet20 -Name Version).Version } 

    # .Net 3.0
    if (Test-Path $rgDotNet30) { $dotNet30 = (Get-ItemProperty -Path $rgDotNet30 -Name Version).Version } 

    # .Net 3.5
    if (Test-Path $rgDotNet35) { $dotNet35 = (Get-ItemProperty -Path $rgDotNet35 -Name Version).Version } 

    # .Net 4.0
    if (Test-Path $rgDotNet40) { $dotNet40 = (Get-ItemProperty -Path $rgDotNet40 -Name Version).Version } 

    # .Net 4.5 and later
    if (Test-Path $rgDotNet45) 
    { 
        $verDWord = (Get-ItemProperty -Path $rgDotNet45 -Name Release).Release 

        switch ($verDWord)
        {
            378389 { $dotNet45 = "4.5"; break } 
            378675 { $dotNet45 = "4.5.1"; break } 
            378758 { $dotNet45 = "4.5.1"; break } 
            379893 { $dotNet45 = "4.5.2"; break } 
            393295 { $dotNet45 = "4.6"; break } 
            393297 { $dotNet45 = "4.6"; break } 
            394254 { $dotNet45 = "4.6.1"; break } 
            394271 { $dotNet45 = "4.6.1"; break }
            394747 { $dotNet45 = "4.6.2"; break } 
            394748 { $dotNet45 = "4.6.2"; break }  
            default { $dotNet45 = "4.5" }
        }
    } 

    $p20 = [ordered]@{ Version = "2.0"; FullVersion = $dotNet20 }
    $p30 = [ordered]@{ Version = "3.0"; FullVersion = $dotNet30 }
    $p35 = [ordered]@{ Version = "3.5"; FullVersion = $dotNet35 }
    $p40 = [ordered]@{ Version = "4.0"; FullVersion = $dotNet40 }
    $p45 = [ordered]@{ Version = "4.5"; FullVersion = $dotNet45 }

    $obj20 = New-Object -TypeName psobject -Property $p20
    $obj30 = New-Object -TypeName psobject -Property $p30
    $obj35 = New-Object -TypeName psobject -Property $p35
    $obj40 = New-Object -TypeName psobject -Property $p40
    $obj45 = New-Object -TypeName psobject -Property $p45

    $verObjects = $obj20, $obj30, $obj35, $obj40, $obj45

 $head = @"
    <style>

    body { background-color:#FFFFFF;
            font-family:Verdana;
            font-size:10pt; 
    }
       
    table { border: 1px solid black;
            width:45%; 
    }

    tr, td, th { border: 1px solid black;
                    align: left;
                    padding: 7px;
                    margin: 0px;        
    }

    th { text-align: left;
        background-color: #4CAF50;
        color: white;
    }
    
    H1 {
        color: green;
    } 

    }
    </style>
    <Title>$title</Title>
"@

    $fragments = $verObjects  | ConvertTo-Html -Fragment -As Table -PreContent "<H1>$title</H1><br>"
    ConvertTo-Html -Title $title -Head $head -Body $fragments | Out-File $outputHtml
    Start-Process $outputHtml
}

Show-MyDotNetVersions
