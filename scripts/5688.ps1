# Creates in global scope PSMenu variable which contained some useful methods.
# Author: greg zakharov
# Known issues: conflicts with ConEmu (reported by 01MDM)
# How does it work?
# Just launch script and it done. Scroll:
# PS> $PSMenu.Scroll()
# Select all:
# PS> $PSMenu.SelectAll()
# Mark a part:
# PS> $PSMenu.Mark()
# Paste:
# PS> $PSMenu.Paste()
# Find:
# PS> $PSMenu.Find()
# Restart PowerShell host:
# PS> $PSMenu.Restart()
# Draw colored line (without message):
# PS> $PSMenu.DrawLine(0, -1, $null, 'White', 'White')
# Draw colored line (with message):
# PS> $PSMenu.DrawLine(0, 1, 'Test message', 'Yellow', 'Blue')
if (!(Test-Path variable:PSMenu)) {
  $PSMenu = New-Object PSObject
  $PSMenu | Add-Member Console -MemberType ScriptMethod -Value {
    param([Int32]$Change)
    
    $SendMessage = [Regex].Assembly.GetType(
      'Microsoft.Win32.UnsafeNativeMethods'
    ).GetMethod(
      'SendMessage'
    )
    
    $GetConsoleWindow = [PSObject].Assembly.GetType(
      'System.Management.Automation.ConsoleVisibility'
    ).GetMethod(
      'GetConsoleWindow', [Reflection.BindingFlags]40
    )
    
    $href = New-Object Runtime.InteropServices.HandleRef(
      (New-Object IntPtr), $GetConsoleWindow.Invoke($null, @())
    )
    
    if ($SendMessage.Invoke($null, @(
      [Runtime.InteropServices.HandleRef]$href,
      0x0111,
      [IntPtr]$Change,
      [IntPtr]::Zero
    )) -ne 0) {
      return
    }
  }
  #Alt+Space actions
  $PSMenu | Add-Member Mark      -MemberType ScriptMethod -Value {$this.Console.Invoke(0xfff2)}
  $PSMenu | Add-Member Paste     -MemberType ScriptMethod -Value {$this.Console.Invoke(0xfff1)}
  $PSMenu | Add-Member SelectAll -MemberType ScriptMethod -Value {$this.Console.Invoke(0xfff5)}
  $PSMenu | Add-Member Scroll    -MemberType ScriptMethod -Value {$this.Console.Invoke(0xfff3)}
  $PSMenu | Add-Member Find      -MemberType ScriptMethod -Value {$this.Console.Invoke(0xfff4)}
  #additional useful methods
  $PSMenu | Add-Member Restart   -MemberType ScriptMethod -Value {
    #locates PowerShell link in All Users directory (instead env:ALLUSERSPROFILE)
    .(Get-ChildItem (Split-Path (
      [Environment]::GetFolderPath('CommonApplicationData')
    )) -r '*powershell.lnk').FullName
    Stop-Process -Id $PID
  }
  $PSMenu | Add-Member DrawLine  -MemberType ScriptMethod -Value {
    param(
      [Int32]$x,
      [Int32]$y,
      [String]$s = $null,
      [ConsoleColor]$fc, #foreground color
      [ConsoleColor]$bc  #background color
    )
    
    $raw = $host.UI.RawUI
    $old = $raw.WindowPosition
    $con = $raw.WindowSize
    $pos = $old
    $pos.X += $x
    $pos.Y += $(switch($y -lt 0){$true{$con.Height + $y}$false{$y}})
    
    switch ([String]::IsNullOrEmpty($s)) {
      $true  {$s = ' ' * $con.Width}
      $false {$s += ' ' * ($con.Width - $s.Length)}
    }
    $row = $raw.NewBufferCellArray(@($s), $fc, $bc)
    $raw.SetBufferContents($pos, $row)
  }
  #set variable as constant
  Set-Variable PSMenu -Value $PSmenu -Option Constant -Scope Global
}
