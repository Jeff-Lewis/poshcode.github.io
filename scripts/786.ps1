#requires -version 2.0
## ISE-Snippets module v 1.0
## DEVELOPED FOR CTP3 
## See comments for each function for changes ...
##############################################################################################################
## As a shortcut for every snippet would be to much, I created Add-Snippet which presents a menu.
## Feel free to add your own snippets to function Add-Snippet but please contribute your changes here
##############################################################################################################
## Provides Code Snippets for working with ISE
## Add-Snippet - Presents menu for snippet selection
## Add-SnippetToEditor - Adds a snippet at caret position
##############################################################################################################


## Add-Snippet
##############################################################################################################
## Presents menu for snippet selection
##############################################################################################################
function Add-Snippet
{
    $snippets = @{
        "region" = @( "#region", "#endregion" )
        "function" = @( "function FUNCTION_NAME", "{", "}" )
        "param" = @( "param ``", "(", ")" )
        "if" = @( "if ( CONDITION )", "{", "}" )
        "else" = @( "else", "{", "}" )
        "elseif" = @( "elseif ( CONDITION )", "{", "}" )
        "foreach" = @( "foreach ( ITEM in COLLECTION )", "{", "}" )
        "for" = @( "foreach ( INIT; CONDITION; REPEAT )", "{", "}" )
        "while" = @( "while ( CONDITION )", "{", "}" )
        "do .. while" = @( "do" , "{", "}", "while ( CONDITION )" )
        "do .. until" = @( "do" , "{", "}", "until ( CONDITION )" )
        "try" = @( "try", "{", "}" )
        "catch" = @( "catch", "{", "}" )
        "catch [<error type>] " = @( "catch [ERROR_TYPE]", "{", "}" )
        "finaly" = @( "finaly", "{", "}" )
    }
    
    Write-Host "Select snippet:"
    Write-Host
    $i = 1
    $snippetIndex = @()
    foreach ( $snippetName in $snippets.Keys | Sort )
    {
        Write-Host ( "{0} - {1}" -f $i++, $snippetName)
        $snippetIndex += $snippetName
    }
    try
    {
        [int]$choice = Read-Host ("Select 1-{0}" -f $i)
        if ( ( $choice -gt 0 ) -and ( $choice -lt $i ) )
        {
            $snippetName = $snippetIndex[$choice -1]
            
            Add-SnippetToEditor $snippets[$snippetName]
        }
        else
        {
            Throw "Choice not in range"
        }
    }
    catch
    {
        Write-Error "Choice was not in range or not even and integer"
    }
}

## Add-SnippetToEditor
##############################################################################################################
## Adds a snippet at caret position
##############################################################################################################
function Add-SnippetToEditor
{
    param `
    (
        [string[]] $snippet
    )

    $editor = $psISE.CurrentOpenedFile.Editor
    $caretLine = $editor.CaretLine
    $caretColumn = $editor.CaretColumn
    $text = $editor.Text.Split("`n")
    $newText = @()
    if ( $caretLine -gt 1 )
    {
        $newText += $text[0..($caretLine -2)]
    }
    $curLine = $text[$caretLine -1]
    $indent = $curline -replace "[^\t ]", ""
    foreach ( $snipLine in $snippet )
    {
        $newText += $indent + $snipLine
    }
    if ( $caretLine -ne $text.Count )
    {
        $newText += $text[$caretLine..($text.Count -1)]
    }
    $editor.Text = [String]::Join("`n", $newText)
    $editor.SetCaretPosition($caretLine, $caretColumn)
}

Export-ModuleMember Add-Snippet


##############################################################################################################
## Inserts command Add Snippet to custom menu
##############################################################################################################
if (-not( $psISE.CustomMenu.Submenus | where { $_.DisplayName -eq "Snippet" } ) )
{
    $null = $psISE.CustomMenu.Submenus.Add("_Snippet", {Add-Snippet}, "Ctrl+Alt+S")
}
