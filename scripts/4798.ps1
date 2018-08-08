Set-Alias sdelete Remove-FileAbnormally

function Remove-FileAbnormally {
  <#
    .SYNOPSIS
        Wipe a file.
    .EXAMPLE
        PS C:\>sdelete E:\bin\whois.exe
    .NOTES
        Author: greg zakharov
        Mailto: gregzakharov@bk.ru
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateScript({Test-Path $_})]
    [String]$FileName,
    
    [Parameter(Position=1)]
    [ValidateRange(1, 32)]
    [Int32]$PassThru = 3
  )
  
  begin {
    $FileName = cvpa $FileName
    
    $buf = New-Object "Byte[]" 512
    $rng = New-Object Security.Cryptography.RNGCryptoServiceProvider
  }
  process {
    try {
      [IO.File]::SetAttributes($FileName, [IO.FileAttributes]::Normal)
      $sectors = [Math]::Ceiling((([IO.FileInfo]$FileName).Length / 512))
      
      $fs = New-Object IO.FileStream($FileName, [IO.FileMode]::Open, [IO.FileAccess]::Write)
      for ($i = 0; $i -lt $PassThru; $i++) {
        for ($j = 0; $j -lt $sectors; $j++) {
          $rng.GetBytes($buf)
          $fs.Write($buf, 0, $buf.Length)
        }
      }
      $fs.SetLength(0)
    }
    catch {
      Write-Host $_.Exception.Message
    }
    finally {
      if ($fs -ne $null) {$fs.Close()}
    }
    
    $stamp = New-Object DateTime($([Int32](date -u %Y) + 23), 1, 1, 0, 0, 0)
    [IO.File]::SetCreationTime($FileName, $stamp)
    [IO.File]::SetLastWriteTime($FileName, $stamp)
    [IO.File]::SetLastAccessTime($FileName, $stamp)
    
    [IO.File]::Delete($FileName)
  }
  end {''}
}
