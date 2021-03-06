function Get-LocalUsers {
  param(
    [Parameter(Position=0)]
    [Alias("o")]
    [Switch]$OnlyLoaded = $false
  )
  
  begin {
    $rk = [Microsoft.Win32.Registry]::Users
    $cur = $rk.GetSubKeyNames() -notmatch '[.|_]' | sort
    $rk.Close()
    
    $key = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'    
  }
  process {
    gci $key | % {$all = @()}{
      $str = "" | select Sid, User, ProfilePath
      $str.Sid = $_.PSChildName
      $str.ProfilePath = (gp ($key + '\' + $_.PSChildName)).ProfileImagePath
      $str.User = Split-Path -leaf $str.ProfilePath
      $all += $str
    }
    
    if ($OnlyLoaded) {
      $arr = @()
      foreach ($a in $all) {
        foreach ($c in $cur) {
          if ($c -match $a.Sid) {$arr += $a}
        }
      }
    }
  }
  end {
    if ($OnlyLoaded) {$arr | ft -a}
    else {$all | ft -a}
  }
}
