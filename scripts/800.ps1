function Sort-ISE ()
{
 <# 
.SYNOPSIS 
    ISE Extension sort text starting at column $start comparing the next $length characters     
.DESCRIPTION 
    ISE Extension sort text starting at column $start comparing the next $length characters
    Leftmost column is column 1     
.NOTES 
    File Name  : Sort-ISE_Boots.ps1 
    Author     : Bernd Kriszio - http://pauerschell.blogspot.com/ 
    Requires   : PowerShell V2 CTP3 
.LINK 
    Script posted to: http://poshcode.org/
.EXAMPLE 
    Sort-ISE  1 10
#> 
#requires -version 2.0
    param (     
        [Parameter(Position = 0, Mandatory=$false)]
        [int]$start = 1,    
        [Parameter(Position = 1, Mandatory=$false)]
        [int]$length = -1    
    )
    "`$start = $Start `$length = $length"     
    $newlines = @{}

    $editor = $psISE.CurrentOpenedFile.Editor
    $caretLine = $editor.CaretLine
    $caretColumn = $editor.CaretColumn
    $text = $text -replace "`r", "-"
    $text = $editor.Text.Split("`n")
    '----------'
    foreach ($i in 0..$($text.length -1 )){
        "$i  $($text[$i])"
    }
    
    foreach ($line in $text){
        $key = [string]::join("", $line[($start - 1)..($start - 1 + $length)])
        if ( $newlines[$key]  -ne $null) {
            $newlines[$key] =  $newlines[$key] + "`n" + $line  
        }
        else {
            $newlines[$key] =  $line
        }
    }
    $Sortedkeys = $newlines.keys | sort
    
    $newtext = ''
    foreach ($key in $Sortedkeys){
        if ($newtext -ne '') {
            $newtext +=  "`n" + $newlines[$key] 
        }
        else {
            $newtext = $newlines[$key]
        }
    }
    ' ======='
    Write-host $newtext
    ' .......'
    
    $text = $newtext.Split("`n")
    foreach ($i in 0..$($text.length -1 )){
        "$i  $($text[$i])"
    }
    #$newtext = $newtext -replace "`n", "`r`n"
    $editor.Text = $newtext
}

function Show-Sort_ISE_DLG {
 <# 
.SYNOPSIS 
    ISE Extension sort text starting at column $start comparing the next $length characters     
.DESCRIPTION 
    ISE Extension sort text starting at column $start comparing the next $length characters
    Leftmost column is column 1. Querry parameters by dialog.     
.NOTES 
    File Name  : Sort-ISE_Boots.ps1 
    Author     : Bernd Kriszio - http://pauerschell.blogspot.com/ 
    Requires   : PowerShell V2 CTP3 
.LINK 
    Script posted to: http://poshcode.org/
.EXAMPLE 
    Sort-ISE  1 10
#> 
#requires -version 2.0
   Param([string]$Prompt = "Please enter start and length:")
   
   Remove-Variable textBox -ErrorAction SilentlyContinue
   
   Border -BorderThickness 4 -BorderBrush "#BE8" -Background "#EFC" (
      StackPanel -Margin 10  $(
         Label $Prompt
         StackPanel -Orientation Horizontal $(
            TextBox -OutVariable global:textbox -Width 150 -On_KeyDown {
               if($_.Key -eq "Return") {
                  #Write-Output $textbox[0].Text
                  #Write-Output $textbox2[0].Text
                  Sort-ISE $textbox[0].Text $textbox2[0].Text
                  $BootsWindow.Close()
               }
            }
            TextBox -OutVariable global:textbox2 -Width 150 -On_KeyDown {
               if($_.Key -eq "Return") {
                  #Write-Output $textbox[0].Text
                  #Write-Output $textbox2[0].Text
                  Sort-ISE $textbox[0].Text $textbox2[0].Text
                  $BootsWindow.Close()
               }
            }
            Button "Ok" -On_Click {
               #Write-Output $textbox[0].Text
               #Write-Output $textbox2[0].Text
               Sort-ISE $textbox[0].Text $textbox2[0].Text
               $BootsWindow.Close()
            }
         )
      )
   ) | Boots -On_Load { $textbox[0].Focus() } `
      -WindowStyle None -AllowsTransparency $true `
      -On_PreviewMouseLeftButtonDown {
         if($_.Source -notmatch ".*\.(TextBox|Button)")
         {
            $BootsWindow.DragMove()
         }
      }
}



if (-not( $psISE.CustomMenu.Submenus | where { $_.DisplayName -eq "_Sort" } ) )
{
    $null = $psISE.CustomMenu.Submenus.Add("_Sort", {Show-Sort_ISE_DLG}, "Ctrl+Alt+S")
}
