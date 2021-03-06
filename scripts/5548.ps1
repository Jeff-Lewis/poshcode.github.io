if (!(Test-Path alias:cal)) { Set-Alias cal Get-Calendar }

function Get-Calendar {
  <#
    .NOTES
        Author: greg zakharov
  #>
  param(
    [Parameter(Position=0)]
    [ValidateRange(1, 12)]
    [Int32]$Month = (date -u %m),
    
    [Parameter(Position=1)]
    [ValidateRange(2000, 9999)]
    [Int32]$Year = (date -u %Y),
    
    [Parameter(Position=2)]
    [Alias('m')]
    [Switch]$MondayFirstly
  )
  
  begin {
    [Globalization.DateTimeFormatInfo]::CurrentInfo.ShortestDayNames | % {$arr = @()}{$arr += $_}
    $cal = [Globalization.CultureInfo]::CurrentCulture.Calendar
    $dow = [Int32]$cal.GetDayOfWeek([DateTime]([String]$Month + '.1.' + [String]$Year))
    if ($MondayFirstly) {
      $arr = $arr[1..$arr.Length] + $arr[0]
      $dow--
    }
  }
  process {
    $loc = [Globalization.DateTimeFormatInfo]::CurrentInfo.MonthNames[$Month - 1] + ' ' + $Year
    $loc = [String]((' ' * [Math]::Round((20 - $loc.Length) / 2)) + $loc)
    
    if ($dow -ne 0) {for ($i = 0; $i -lt $dow; $i++) {$arr += (' ' * 2)}}
    1..$cal.GetDaysInMonth($Year, $Month) | % {
      if ($_.ToString().Length -eq 1) {$arr += ' ' + [String]$_}
      else {$arr += [String]$_}
    }
  }
  end {
    Write-Host $loc -fo Magenta
    for ($i = 0; $i -lt $arr.Length; $i += 6) {
      Write-Host $arr[$i..($i + 6)]
      $i++
    }
    ''
  }
}
