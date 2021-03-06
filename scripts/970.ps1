#requires -version 2

# some PowerShell Functions to scan VB 6 Projects for patterns
# e.g. some SQL calls
 
# by Bernd Kriszio http://pauerschell.blogspot.com/

function Get-VBProject ($file)
{
    # this is developed for use with Visual Basic 6
    # to extract the files the contain VB Code
    pushd (Split-path $file)
    foreach ($line in (gc $file))
    {
        if ($line -match "Class=\S+;\s+(\S+.cls)")
        {
            gi $matches[1]
        }
        elseif ($line -match "Form=(\S+.frm)")
        {
            gi $matches[1]
        }
        elseif ($line -match "Module=\S+;\s*(\S+.BAS)")
        {
            gi $matches[1]
        }
    }
    popd

}

function Get-VBLines ($file)
{
    # VB 6 uses _ at end of line as line continuation character
    # we build logical VB lines, especially to get complete signatures of functions and subroutines
    $oFile = gi $file
    $SourceLineNumber = 0
    foreach ($line in (gc $file))
    {
        $SourceLineNumber++
        if ($continue)
        {
            $buffer += "`r`n" + $line 
            if ($line -notmatch '_$') 
            { 
                $continue = $False
                $o = New-Object object
		        Add-Member -InputObject $o -MemberType NoteProperty -Name LineNumber -Value $LineNumber
		        Add-Member -InputObject $o -MemberType NoteProperty -Name VBLine     -Value $buffer
		        Add-Member -InputObject $o -MemberType NoteProperty -Name file       -Value $oFile.Name
		        Add-Member -InputObject $o -MemberType NoteProperty -Name filepath   -Value $oFile.FullName
                $o
            }
        }
        else
        {
            $buffer = $line 
            $LineNumber = $SourceLineNumber 
            if ($line -match '_$') 
            { 
                $continue = $True
            }
            else
            {
                $o = New-Object object
		        Add-Member -InputObject $o -MemberType NoteProperty -Name LineNumber -Value $LineNumber
		        Add-Member -InputObject $o -MemberType NoteProperty -Name VBLine     -Value $buffer
		        Add-Member -InputObject $o -MemberType NoteProperty -Name file       -Value $oFile.Name
		        Add-Member -InputObject $o -MemberType NoteProperty -Name filepath   -Value $oFile.FullName
                $o
            }
        }
        
    }
}
 
function Get-VB_CodeObject ()
{
    param (     
        [Parameter(Position = 0, Mandatory=$true, ValueFromPipeline=$True)]
        $file    
    )     
    PROCESS
    {
        $inObject = $False
        $lines = @()
        $comments = @()
        $inDeclareations = $True
        #write-Host "--- $file ----"
        Get-VBLines $file  | %  {
            if ($inObject)
            {
                if ($_.VBLine -match "^End $end")
                {
                    $lines += $_.VBLine
                    $inObject = $False
                    if ($inDeclareations){
                        $o = New-Object object
        		        Add-Member -InputObject $o -MemberType NoteProperty -Name LineNumber -Value 1
        		        Add-Member -InputObject $o -MemberType NoteProperty -Name Code       -Value $comments
        		        Add-Member -InputObject $o -MemberType NoteProperty -Name Comments   -Value ''

        		        Add-Member -InputObject $o -MemberType NoteProperty -Name file       -Value $_.file
        		        Add-Member -InputObject $o -MemberType NoteProperty -Name filepath   -Value $_.filepath

        		        Add-Member -InputObject $o -MemberType NoteProperty -Name acces      -Value ''
        		        Add-Member -InputObject $o -MemberType NoteProperty -Name typ        -Value ''
        		        Add-Member -InputObject $o -MemberType NoteProperty -Name name       -Value 'Declarations'
                        $inDeclareations = $false
                        $o
                        $comments = @()
                    }

                    $o = New-Object object
    		        Add-Member -InputObject $o -MemberType NoteProperty -Name LineNumber -Value $LineNumber
    		        Add-Member -InputObject $o -MemberType NoteProperty -Name Code       -Value $lines
       		        Add-Member -InputObject $o -MemberType NoteProperty -Name Comments   -Value $comments
                  
                    
    		        Add-Member -InputObject $o -MemberType NoteProperty -Name file       -Value $_.file
    		        Add-Member -InputObject $o -MemberType NoteProperty -Name filepath   -Value $_.filepath

    		        Add-Member -InputObject $o -MemberType NoteProperty -Name acces      -Value $acces
    		        Add-Member -InputObject $o -MemberType NoteProperty -Name typ        -Value $typ
    		        Add-Member -InputObject $o -MemberType NoteProperty -Name name       -Value $name
                    $o
                    $lines = @()
                }
                else
                { # collect lines
                    $lines += $_.VBLine
                }
            }
            else
            {     
                if ($_.VBLine -match "^(Public|Private)?\s*Property\s+(Get|Set)\s+([^\s\(]+)")
                {
                    $acces = $matches[1]
                    $typ = 'Property ' + $matches[2]
                    $name = $matches[3]
                    $end =  'Property'
                    $inObject = $True
                    #$acces + " " +  $typ + " " + $name
                    $comments = $lines
                    $lines = (, $_.VBLine)
                    $LineNumber = $_.LineNumber
                    
                }
                elseif ($_.VBLine -match "^(Public|Private)?\s*(Function|Sub)\s+([^\s\(]+)")
                {
                    $acces = $matches[1]
                    $typ = $matches[2]
                    $name = $matches[3]
                    $end = $matches[2]
                    $inObject = $True
                    #$acces + " " +  $typ + " " + $name
                    $comments = $lines
                    $lines = (, $_.VBLine)
                    $LineNumber = $_.LineNumber
                }
                else
                {
                    $lines += $_.VBLine
                }
            }
        }
    }
}


filter Select-VBCode_String ($pattern)
{
    $o = New-Object object
    Add-Member -InputObject $o -MemberType NoteProperty -Name LineNumber -Value $_.LineNumber
   	Add-Member -InputObject $o -MemberType NoteProperty -Name Comments   -Value $_.comments
    
    Add-Member -InputObject $o -MemberType NoteProperty -Name file       -Value $_.file
    Add-Member -InputObject $o -MemberType NoteProperty -Name filepath   -Value $_.filepath

	Add-Member -InputObject $o -MemberType NoteProperty -Name acces      -Value $_.acces
    Add-Member -InputObject $o -MemberType NoteProperty -Name typ        -Value $_.typ
	Add-Member -InputObject $o -MemberType NoteProperty -Name name       -Value $_.name

    $patternFound = $False
    $lines = @() 
    foreach ($l in $_.Code)
    {
        if ($l -match $pattern)
        {
            $lines += $l
            $patternFound = $True
        }
    }
    if ( $patternFound)
    {
        Add-Member -InputObject $o -MemberType NoteProperty -Name Code       -Value $lines
        $o
    }

}


<#
    $myVBProject = 'myDirtyVb6Project.vbp'
    
    
    $vbp = Get-VBProject $myVBProject | Get-VB_CodeObject 

    # Now you search your VB Project for patterns
    
    # look for sql SELECT-Statements
    $vbp | Select-VBCode_String('"select') |% { $_.code }

    # or the location of Vb EXIT Statments
    $vbp| Select-VBCode_String('EXIT') | fl

    $vbp| select file, acces, typ, name

#>

