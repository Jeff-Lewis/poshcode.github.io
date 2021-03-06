    <#
        .Synopsis
	       Gets the daily woot deal from woot.com.
        .Description
            Gets product description and price of the daily woot deal from the woot.com website.
        .Outputs
            Custom object containing two (2) NoteProperties: Product and Price.
        .Parameter URL
            The URL to load and search for pricing.  Don't get funky, this HAS to be the woot website url, as the code
			won't work with anything else, because it screen scrapes for information.
		.Notes
			This script uses the Webrequest class to load a webpage (woot.com), then does a regex search of the html code
			to find some specific information (also known as 'screen scraping').  This was a learning exercise I inflicted
			upon myself with the goal of using xml parsers (such as the xmldocument class) to reliably extract information
			from xhtml-compliant websites (of which woot.com purports to be, at least according to their page headers :))
			It was a nightmare.  I ran into all kinds of compliance issues with the xml classes, and so after much
			frustration, achieved the goal using a completely different method.
    #>

param(
[Parameter(Position=0, Mandatory=$false)]
[string] $URL = "http://www.woot.com"
)

[string]$WorkingDir = Split-Path $MyInvocation.MyCommand.Path -Parent

$Request = [System.Net.Webrequest]::Create($URL)
$Response = $Request.GetResponse()
$RawStream = $Response.GetResponseStream()
$Encoding = [System.Text.Encoding]::GetEncoding("utf-8") ## better safe than sorry
$EncodedStream = New-Object System.IO.StreamReader($RawStream, $Encoding)
$Data = $EncodedStream.ReadToEnd()

$Product = [regex]::Match($Data,"(?<=<h2\sclass=`"fn`">).+(?=</h2>)").Value
$Price = [regex]::Match($Data,"(?<=<span\sclass=`"amount`">)[0-9\.]+(?=</span>)").Value

$Output = New-Object Object | 
    Add-Member NoteProperty -Name Product -Value $Product -PassThru |
    Add-Member NoteProperty -Name Price -Value $Price -PassThru
Write-Output $Output
Send-MailMessage    -To "<INSERT YOUR EMAIL HERE>" `
                    -From "dailydeal@woot.com" `
                    -Subject "Daily Woot! Deal" `
                    -Body ($Output | Format-Table -AutoSize | Out-String) `
                    -SmtpServer "<INSERT YOUR SMTP SERVER HERE>"
                    
$EncodedStream.Close()
$Response.Close()

break
#experimental stuff
Set-Content -Value $Data -Path "$WorkingDir\Get-Webpage_Data.xhtml" -Force

try {
    
} catch {
    Write-Host $_
} finally {
    $XmlReader.Close()
}
