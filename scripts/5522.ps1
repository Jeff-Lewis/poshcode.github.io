#.Synopsis
#   Split a file into many files, based on a regular expression boundary
#.Example
#   Split-File huge.sql -Pattern '^GO$'
#
#   Splits a SQL file into many pieces, with "GO" as the last line in each resulting file
#.Example
#   Split-File -Path .\huge.sql -Pattern "^print 'Processed \d+ total records'$" -Encoding ([Text.Encoding]::Unicode) -Verbose
#
#   Splits the sql file based on the "processed 100 total records" line, using unicode encoding, while streaming to verbose output the number of lines in each file.

[CmdletBinding()]
param(
    # The path to the text file to split
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Path,

    # The encoding to use to read and write files (uses [Text.Encoding]::Default by default)
    # You may want to use [Text.Encoding]::Unicode
    [Text.Encoding]$Encoding = [Text.Encoding]::Default,

    # A Regular Expression pattern to split on
    [Parameter(ParameterSetName="Pattern", Mandatory=$true, Position=0)]
    [string]$Pattern,

    # An optional header to add to every file
    [String]$Header

    # [Parameter(ParameterSetName="LineCount", Mandatory=$true)]
    # [int]$LineCount,
)
$Path = Convert-Path $Path
Write-Verbose "Opening Reader for $Path"
$Reader = New-Object IO.StreamReader $Path, $Encoding
$Extension = [IO.Path]::GetExtension($Path)

$FileCount = 0
$LineIndex = 0
try {
    if($Pattern) {
        sls -Path $Path -pattern $Pattern | ForEach {
            $Match = $_

            $FileCount += 1
            $FileName = [IO.Path]::ChangeExtension($Path, ".${FileCount}${Extension}")
            $Writer = New-Object IO.StreamWriter $FileName, $false, $Encoding

            Write-Verbose "Writing $($Match.LineNumber - $LineIndex) lines to $(Resolve-Path $FileName -Relative)"
            if($Header) { $Writer.Write($Header + "`r`n") }
            try {
                for(; $LineIndex -lt $Match.LineNumber; $LineIndex++) {
                    $Writer.Write( $Reader.ReadLine() + "`r`n")
                }
            } catch {
                throw $_
            } finally {
                Write-Debug "Closing Writer"
                $Writer.Close()
            }
        }

        # Catch the tail end of the file:
        $FileCount += 1
        $FileName = [IO.Path]::ChangeExtension($Path, ".${FileCount}${Extension}")
        $Writer = New-Object IO.StreamWriter $FileName, $false, $Encoding
        Write-Verbose "Writing the rest to $(Resolve-Path $FileName -Relative)"
        $LastFile = $LineIndex
        try {
            while($Reader.Peek() -ge 0) {
                $LineIndex++
                $Writer.Write( $Reader.ReadLine() + "`r`n")
            }
        } catch {
            throw $_
        } finally {
            Write-Verbose "Wrote $($LineIndex -$LastFile) lines to $(Resolve-Path $FileName -Relative)"
            Write-Debug "Closing Writer"
            $Writer.Close()
        }
    }
} finally {
    Write-Debug "Closing Reader"
    $Reader.Close()
}
