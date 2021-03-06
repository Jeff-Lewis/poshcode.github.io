#
#.SYNOPSIS
# Svendsen Tech's PowerShell ASCII art script creates ASCII art characters
# from a subset of common letters, numbers and punctuation characters.
# You can add new characters by editing the XML and updating the
# $AcceptedChars regexp.
#
# Author: Joakim Svendsen, Svendsen Tech
#
#.DESCRIPTION
# This script reads characters (it started out as letters so the variable
# names are not precise) from an XML file. If you include new characters
# in the XML, you will need to add them to the regular expression assigned
# to the variable $AcceptedChars.
#
# It was written to be used in conjunction with a modified version of
# PowerBot (http://poshcode.org/2510), a simple IRC bot framework written
# using SmartIrc4Net; that's why it prepends an apostrophe by default
# because somewhere along the way the leading spaces get lost before it
# hits the IRC channel.
#
# Currently the XML only contains lowercase letters.
#
# Example:
# PS E:\ASCII-letters> .\Write-ASCII-Letters.ps1 -NoPrependChar "ASCII!"
#                    _  _  _
#   __ _  ___   ___ (_)(_)| |
#  / _` |/ __| / __|| || || |
# | (_| |\__ \| (__ | || ||_|
#  \__,_||___/ \___||_||_|(_)
# PS E:\ASCII-letters>
#
#.PARAMETER InputText
# String(s) to convert to ASCII.
#.PARAMETER NoPrependChar
# Makes the script not prepend an apostrophe.
#.PARAMETER TextColor
# Optional. Console only. Changes color of output.
#>

param(
    [string[]] $InputText,
    [switch] $NoPrependChar,
    [string] $TextColor = 'Default'
    #[int] $MaxChars = '25'  
    )

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Populate the $Letters hashtable with character data from the XML.
Function Parse-LetterXML {
    
    $LetterFile = '.\letters.xml'
    $Xml = [xml] (Get-Content $LetterFile)
    
    $Xml.Letters.Letter | ForEach-Object {
        
        $Letters.($_.Name) = New-Object PSObject -Property @{
            
            'Lines' = $_.Lines
            'ASCII' = $_.Data
            'Width' = $_.Width
        }
        
    }
    
}

# Algorithm from hell... This was painful. I hope there's a better way.
function Create-ASCII-Text {
    
    param([string] $Text)
    
    $LetterArray = [char[]] $Text.ToLower()
    
    #Write-Host -fore green $LetterArray
    
    # Find the letter with the most lines.
    $MaxLines = 0
    $LetterArray | ForEach-Object { if ($Letters.([string] $_).Lines -gt $MaxLines ) { $MaxLines = $Letters.([string] $_).Lines } }
    
    $LetterWidthArray = $LetterArray | ForEach-Object { $Letter = [string] $_; $Letters.$Letter.Width }
    $LetterLinesArray = $LetterArray | ForEach-Object { $Letter = [string] $_; $Letters.$Letter.Lines }
    
    #$LetterLinesArray
    
    $Lines = @{
        '1' = ''
        '2' = ''
        '3' = ''
        '4' = ''
        '5' = ''
        '6' = ''
    }
    
    #$LineLengths = @(0, 0, 0, 0, 0, 0)
        
    $LetterPos = 0
    foreach ($Letter in $LetterArray) {
        
        # We need to work with strings for indexing the hash by letter
        $Letter = [string] $Letter
        
        # Each ASCII letter can be from 4 to 6 lines.
        
        # If the letter has the maximum of 6 lines, populate hash with all lines.
        if ($LetterLinesArray[$LetterPos] -eq 6) {
            
            foreach ($Num in 1..6) {
                
                $StringNum = [string] $Num
                
                $LineFragment = [string](($Letters.$Letter.ASCII).Split("`n"))[$Num-1]
                
                if ($LineFragment.Length -lt $Letters.$Letter.Width) {
                    $LineFragment += ' ' * ($Letters.$Letter.Width - $LineFragment.Length)
                }
                
                $Lines.$StringNum += $LineFragment
                
            }
            
        }
        
        # Add padding for line 6 for letters with 5 lines and populate lines 2-6.
        elseif ($LetterLinesArray[$LetterPos] -eq 5) {
            
            $Padding = ' ' * $LetterWidthArray[$LetterPos]
            $Lines.'1' += $Padding
            
            foreach ($Num in 2..6) {
                
                $StringNum = [string] $Num
                
                $LineFragment = [string](($Letters.$Letter.ASCII).Split("`n"))[$Num-2]
                
                if ($LineFragment.Length -lt $Letters.$Letter.Width) {
                    $LineFragment += ' ' * ($Letters.$Letter.Width - $LineFragment.Length)
                }
                    
                $Lines.$StringNum += $LineFragment
                
            }
        
            
        }
        
        # Here we deal with letters with four lines.
        # Dynamic algorithm that places four-line letters on the bottom line if there are
        # 4 or 5 lines only in the letter with the most lines.
        else {
            
            # Default to putting the 4-liners at line 3-6
            $StartRange, $EndRange, $IndexSubtract = 3, 6, 3
            $Padding = ' ' * $LetterWidthArray[$LetterPos]
            
            # If there are 4 or 5 lines...
            if ($MaxLines -lt 6) {
                
                $Lines.'2' += $Padding
                
            }
           
            # There are 6 lines maximum, put 4-line letters in the middle.
            else {
                
                $Lines.'1' += $Padding
                $Lines.'6' += $Padding
                $StartRange, $EndRange, $IndexSubtract = 2, 5, 2
                
            }
            
            # There will always be at least four lines. Populate lines 2-5 or 3-6 in the hash.
            foreach ($Num in $StartRange..$EndRange) {
                
                $StringNum = [string] $Num
                
                $LineFragment = [string](($Letters.$Letter.ASCII).Split("`n"))[$Num-$IndexSubtract]
               
                if ($LineFragment.Length -lt $Letters.$Letter.Width) {
                    $LineFragment += ' ' * ($Letters.$Letter.Width - $LineFragment.Length)
                }
                
                $Lines.$StringNum += $LineFragment
                
            }
                
        }
                    
        $LetterPos++
        
    } # end of LetterArray foreach
    
    # Return stuff
    $Lines.GetEnumerator() | Sort Name | Select -ExpandProperty Value | ?{ $_ -match '\S' } | %{ if ($NoPrependChar) { $_ } else { "'" + $_ } }
    
}

# Get ASCII art letters/characters and data from XML.
$Letters = @{}
Parse-LetterXML

# Turn the [string[]] into a [string] the only way I could figure out how... wtf
$Text = ''
$InputText | ForEach-Object { $Text += "$_ " }

# Limit to 30 characters
$MaxChars = 30
if ($Text.Length -gt $MaxChars) { "Too long text. There's a maximum of $MaxChars characters."; exit }

# Replace spaces with underscores.
$Text = $Text -replace ' ', '_'

# Define accepted characters (which are found in XML).
$AcceptedChars = '[^a-z0-9 _,!?./;:<>(){}\[\]''\-\\"æøå]' # æøå only works when sent as UTF-8 on IRC
if ($Text -match $AcceptedChars) { "Unsupported character, using this 'accepted chars' regex: $AcceptedChars."; exit }

# Filthy workaround (now worked around in the foreach creating the string).
#if ($Text.Length -eq 1) { $Text += '_' }

$Lines = @()
$ASCII = Create-ASCII-Text $Text

if ($TextColor -ne 'Default') { Write-Host -ForegroundColor $TextColor ($ASCII -join "`n") }
else { $ASCII }
