####################################################################################################
## Write-Sitemap.ps1
##
## Generates a basic Sitemap for your website, based on a list of locations / products or whatever,
## (depending on your requirements). Can easily be extended to create more complex Sitemaps.
## 
## This uses XMLTextWriter and is based on the RSS creator script at 
## http`://pshscripts.blogspot.com/2008/12/write-rssstreamps1.html
##
## Note the URLs in this script have been escaped. You may have to remove the backticks.
####################################################################################################
## Sitemap format, as output by this script (see http`://www.sitemaps.org/protocol.php for more)
##
## <?xml version="1.0" encoding="utf-8"?>
## <urlset xmlns="http`://www.google.com/schemas/sitemap/0.9">
##  <url>
##   <loc>http`://your.url/here/product1</loc>
##  </url>
##  <url>
##   <loc>http`://your.url/here/product2</loc>
##  </url>
## </urlset>
####################################################################################################

# Let's Set up some variables
$workingdir = "c:\scripts"
$Domain 	= "http`://www.somesite.url"		# Base URL - CHANGE THIS!
$path 		= "$workingdir\sitemap.xml"		# Where the output file will go


$Statics 	= @("help", "contact", "terms", "privacy") 	# Any static links go here
$Locations 	= Get-Content "$workingdir\products.txt"    # A list of product IDs

$Counter 	= 0		# Keep track of how many URLs we include. Must be less than 50k per file.

# This function does the bulk of the work, creating a new <url> and <loc> element for each URL
function CreateElement([string]$url)
{
	$w = $global:writer
	$w.WriteStartElement("url")
	$w.WriteStartElement("loc")
	$w.WriteString($url)
	$w.WriteEndElement() #end loc
	$w.WriteEndElement() #end url

	$global:counter++	# Increment URL counter
}

#### MAIN #####

# Set up encoding, and create new instance of XMLTextWriter
$encoding = [System.Text.Encoding]::UTF8
$writer = New-Object System.Xml.XmlTextWriter( $Path, $encoding )
$writer.Formatting = [system.xml.formatting]::indented

Write-Host "`r`n`r`nGenerating $Domain Sitemap... $path"

# Write start of XML document
$writer.WriteStartDocument()

# Write Start of sitemap doc
$writer.WriteStartElement( "urlset" )
$writer.WriteAttributeString( "xmlns", "http`://www.sitemaps.org/schemas/sitemap/0.9" )

# Write our static URLs
foreach ($static in $statics)
{
	CreateElement "$Domain/$Static"
}

# Write all location URLs
foreach ($Location in $Locations)
{
	$r = "$domain/product/$location"
	CreateElement $r
}

# You could add more URL definitions here as needed...

# Write end of document information
$writer.WriteEndElement() # End urlset

# Make sure we close the file
$writer.close()

# Let's see what it has done
# cat $path

# See how many elements were output
Write-Host "`n`rTotal number of URLs : $Counter"
# If this is more than 50,000 we should split into multiple sitemap files...
