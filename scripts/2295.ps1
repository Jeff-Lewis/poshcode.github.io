## Set-WindowTransparent.ps1
## 
##
Add-Type -Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;

namespace TE
{
  public static class Win32Methods
  {
  
    internal const int GWL_EXSTYLE = -20;
    internal const int WS_EX_LAYERED = 0x80000;
    internal const int LWA_ALPHA = 0x2;
    internal const int LWA_COLORKEY = 0x1;
     
    [DllImport("user32.dll")]
    internal static extern bool SetLayeredWindowAttributes(IntPtr hwnd, uint crKey, byte bAlpha, uint dwFlags);
    
    [DllImport("user32.dll")]
    internal static extern int SetWindowLong(IntPtr hWnd, int nIndex, int dwNewLong);
    
    [DllImport("user32.dll")]
    internal static extern int GetWindowLong(IntPtr hWnd, int nIndex);
    
    public static void SetWindowTransparent(IntPtr hWnd)
    {
      SetWindowLong(hWnd, GWL_EXSTYLE, GetWindowLong(hWnd, GWL_EXSTYLE) ^ WS_EX_LAYERED);
      SetLayeredWindowAttributes(hWnd, 0, 230, LWA_ALPHA);
    }
    
   }
}

"@

$hwnd = (Get-Process -Id $pid).MainWindowHandle
[TE.Win32Methods]::SetWindowTransparent($hwnd)

