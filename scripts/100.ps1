# Highlight-Syntax.ps1
# version 1.0
# by Jeff Hillman
#
# this script uses regular expressions to highlight PowerShell
# syntax with HTML.

param( [string] $code, [switch] $LineNumbers )

if ( Test-Path $code -ErrorAction SilentlyContinue )
{
    $code = Get-Content $code | Out-String
}

$backgroundColor = "#DDDDDD"
$foregroundColor = "#000000"
$stringColor     = "#800000"
$commentColor    = "#008000"
$operatorColor   = "#C86400"
$numberColor     = "#800000"
$keywordColor    = "#C86400"
$typeColor       = "#404040"
$variableColor   = "#000080"
$cmdletColor     = "#C86400"
$lineNumberColor = "#404040"

filter Html-Encode( [switch] $Regex )
{
    # some regular expressions operate on strings that have already
    # been through this filter, so the patterns need to be updated
    # to look for the encoded characters instead of the literal ones.
    # we do it with this filter instead of directly in the regular 
    # expression so the expressions can be a bit more readable (ha!)

    $_ = $_ -replace "&", "&amp;"
    
    if ( $Regex )
    {
        $_ = $_ -replace "(?<!\(\?)<", "&lt;"
        $_ = $_ -replace "(?<!\(\?)>", "&gt;"
    }
    else
    {
        $_ = $_ -replace "\t", "    "
        $_ = $_ -replace " ", "&nbsp;"
        $_ = $_ -replace "<", "&lt;"
        $_ = $_ -replace ">", "&gt;"
    }
    
    $_
}

# regular expressions

$operatorRegex =  @"
((?x:
 (?# assignment operators)
 =|\+=|-=|\*=|/=|%=|
 (?# arithmatic operators)
 (?<!\de)
 (\+|-|\*|/|%)(?![a-z])|
 (?# unary operators)
 \+\+|\-\-|
 (?# logical operators)
 (-and|-or|-not)\b|!|
 (?# bitwise operators)
 (-band|-bor)\b|
 (?# redirection and pipeline operators)
 2>>|>>|2>&1|1>&2|2>|>|<|\||
 (?# comparison operators)
 (
  -[ci]? (?# case and case-insensitive variants)
  (eq|ne|ge|gt|lt|le|like|notlike|match|notmatch|replace|contains|notcontains)\b
 )|
 (?# type operators)
 (-is|-isnot|-as)\b|
 (?# range and miscellaneous operators)
 \.\.|(?<!\d)\.(?!\d)|&|::|:|,|``|
 (?# string formatting operator)
 -f\b
))
"@ | Html-Encode -Regex

$numberRegex = @"
((?x:
 (
  (?# hexadecimal numbers)
  (\b0x[0-9a-f]+)|
  (?# regular numbers)
  (?<!&)
  ((\b[0-9]+(\.(?!\.))?[0-9]*)|((?<!\.)\.[0-9]+))
  (?!(>>|>&[12]|>))
  (?# scientific notation)
  (e(\+|-)?[0-9]+)?
 )
 (
  (?# type specifiers)
  (l|ul|u|f|ll|ull)?
  (?# size shorthand)
  (b|kb|mb|gb)?
  \b
 )?
))
"@ | Html-Encode -Regex

$keyWordRegex = @"
((?x:
 \b(
 (?# don't match anything that looks like a variable or a parameter)
 (?<![-$])
 (
  (?# condition keywords)
  if|else|elseif|(?<!\[)switch(?!\])|
  (?# loop keywords)
  for|(?<!\|</span>&nbsp;)foreach(?!-object)|in|do|while|until|default|break|continue|
  (?# scope keywords)
  global|script|local|private|
  (?# block keywords)
  begin|process|end|
  (?# other keywords)
  function|filter|param|throw|trap|return
 )
 )\b
))
"@

$typeRegex = @"
((?x:
 \[
 (
  (?# primitive types and arrays of those types)
  ((int|long|string|char|bool|byte|double|decimal|float|single)(\[\])?)|
  (?# other types)
  regex|array|xml|scriptblock|switch|hashtable|type|ref|psobject|wmi|wmisearcher|wmiclass
 )
 \]
))
"@

$cmdletNames = Get-Command -Type Cmdlet | Foreach-Object { $_.Name }

function Highlight-Other( [string] $code )
{
    $highlightedCode = $code | Html-Encode
    
    # operators
    $highlightedCode = $highlightedCode -replace 
        $operatorRegex, "<span style='color: $operatorColor'>`$1</span>"

    # numbers
    $highlightedCode = $highlightedCode -replace 
        $numberRegex, "<span style='color: $numberColor'>`$1</span>"

    # keywords
    $highlightedCode = $highlightedCode -replace 
        $keyWordRegex, "<span style='color: $keywordColor'>`$1</span>"

    # types
    $highlightedCode = $highlightedCode -replace 
        $typeRegex, "<span style='color: $typeColor'>`$1</span>"

    # Cmdlets
    $cmdletNames | Foreach-Object {
        $highlightedCode = $highlightedCode -replace 
            "\b($_)\b", "<span style='color: $cmdletColor'>`$1</span>"
    }

    $highlightedCode
}

$RegexOptions = [System.Text.RegularExpressions.RegexOptions]

$highlightedCode = ""

# we treat variables, strings, and comments differently because we don't 
# want anything inside them to be highlighted.  we combine the regular 
# expressions so they are mutually exclusive

$variableRegex = '(\$(\w+|{[^}`]*(`.[^}`]*)*}))'

$stringRegex = @"
(?x:
 (?# here strings)
 @[`"'](.|\n)*?^[`"']@|
 (?# double-quoted strings)
 `"[^`"``]*(``.[^`"``]*)*`"|
 (?# single-quoted strings)
 '[^'``]*(``.[^'``]*)*'
)
"@

$commentRegex = "#[^\r\n]*"

[regex]::Matches( $code, 
                  "(?<before>(.|\n)*?)" + 
                  "((?<variable>$variableRegex)|" + 
                  "(?<string>$stringRegex)|" + 
                  "(?<comment>$commentRegex))",
                  $RegexOptions::MultiLine ) | Foreach-Object {
    # highlight everything before the variable, string, or comment    
    $highlightedCode += Highlight-Other $_.Groups[ "before" ].Value

    if ( $_.Groups[ "variable" ].Value )
    {
        $highlightedCode += 
            "<span style='color: $variableColor'>" + 
            ( $_.Groups[ 'variable' ].Value | Html-Encode ) + 
            "</span>"
    }
    elseif ( $_.Groups[ "string" ].Value )
    {
        $string = $_.Groups[ 'string' ].Value | Html-Encode
        
        $string = "<span style='color: $stringColor'>$string</span>"

        # we have to highlight each piece of multi-line strings
        if ( $string -match "\r\n" )
        {
            # highlight any line continuation characters as operators
            $string = $string -replace 
                "(``)(?=\r\n)", "<span style='color: $operatorColor'>``</span>"

            $string = $string -replace 
                "\r\n", "</span>`r`n<span style='color: $stringColor'>"
        }

        $highlightedCode += $string
    }
    else
    {
        $highlightedCode += 
            "<span style='color: $commentColor'>" + 
            $( $_.Groups[ 'comment' ].Value | Html-Encode ) + 
            "</span>"
    }

    # we need to keep track of the last position of a variable, string, 
    # or comment, so we can highlight everything after it
    $lastMatch = $_
}

if ( $lastMatch )
{
    # highlight everything after the last variable, string, or comment   
    $highlightedCode += Highlight-Other $code.SubString( $lastMatch.Index + $lastMatch.Length )
}
else
{
    $highlightedCode = Highlight-Other $code
}

# add line breaks
$highlightedCode = 
    [regex]::Replace( $highlightedCode, '(?=\r\n)', '<br />', $RegexOptions::MultiLine )

# put the highlighted code in the pipeline
"<div style='width: 100%; " + 
            "/*height: 100%;*/ " +
            "overflow: auto; " +
            "font-family: Consolas, `"Courier New`", Courier, mono; " +
            "font-size: 12px; " +
            "background-color: $backgroundColor; " +
            "color: $foregroundColor; " + 
            "padding: 2px 2px 2px 2px; white-space: nowrap'>"

if ( $LineNumbers )
{
    $digitCount = 
        ( [regex]::Matches( $highlightedCode, "^", $RegexOptions::MultiLine ) ).Count.ToString().Length

    $highlightedCode = [regex]::Replace( $highlightedCode, "^", 
        "<li style='color: $lineNumberColor; padding-left: 5px'><span style='color: $foregroundColor'>",
        $RegexOptions::MultiLine )

    $highlightedCode = [regex]::Replace( $highlightedCode, "<br />", "</span><br />",
        $RegexOptions::MultiLine )
    
    "<ol start='1' style='border-left: " +
                         "solid 1px $lineNumberColor; " +
                         "margin-left: $( ( $digitCount * 10 ) + 15 )px; " +
                         "padding: 0px;'>"
}

$highlightedCode

if ( $LineNumbers )
{
    "</ol>"
}

"</div>"

