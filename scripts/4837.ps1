#There are a lot of ways to copy\paste text from the clipboard. For example, you can use context menu of host which
#is called with Alt+Space combination or use standard clip utility or third party modules and extensions. But all
#this is not a way a true Jedi ;) At firstly you can use Clipboard class which defined into System.Windows.Forms
#namespace but note that it requires STA mode.
if ($host.Runspace.ApartmentState -ne 'STA') {
  powershell /noprofile /sta $MyInvocation.MyCommand.Path
  return
}

function Invoke-Clipboard([String]$Text, [Switch]$Paste) {
  begin {
    $asm = 'System.Windows.Forms'
    if (!([AppDomain]::CurrentDomain.GetAssemblies() | ? {
      $_.FullName.Split(',')[0] -eq $asm
    })) {[void][Reflection.Assembly]::LoadWithPartialName($asm)}
  }
  process {
    switch($Paste) {
      $true {[Windows.Forms.Clipboard]::GetText()}
      default {[Windows.Forms.Clipboard]::SetText($Text)}
    }
  }
  end {}
}
#Copy text
#PS C:\>Invoke-Clipboard 'This is a test string'
#Paste
#PS C:\>Invoke-Clipboard -p
#That's good but there is alternative way without STA. Next function is completely analogous to the previous except
#that it does not require STA mode verification.
function Invoke-Clipboard([String]$Text, [Switch]$Paste) {
  begin {
    $asm = 'System.Windows.Forms'
    if (!([AppDomain]::CurrentDomain.GetAssemblies() | ? {
      $_.FullName.Split(',')[0] -eq $asm
    })) {[void][Reflection.Assembly]::LoadWithPartialName($asm)}
    
    $txtClip = New-Object Windows.Forms.TextBox
    $txtClip.Multiline = $true
  }
  process {
    switch($Paste) {
      $true {
        $txtClip.Paste()
        $txtClip.Text
      }
      default {
        $txtClip.Text = $Text
        $txtClip.SelectAll()
        $txtClip.Copy()
      }
    }
  }
  end {}
}
#OK, how about PInvoke? In principle, you can use PInvoke methods that has been encapsulated in the .NET platform
#assemblies. For example (http://poshcode.org/4750):
function Get-HostPaste {
  begin {
    if (@(ps powershell).Count -gt 1) {
      throw "More than one host running."
    }
    
    function get([String]$Assembly, [String]$Class, [String]$Method, [Switch]$Flags) {
      $type = ([AppDomain]::CurrentDomain.GetAssemblies() | ? {
        $_.Location.Split('\')[-1].Equals($Assembly)
      }).GetType($Class)
      
      switch ($Flags) {
        $true {$res = $type.GetMethod($Method, [Reflection.BindingFlags]'NonPublic, Static')}
        default {$res = $type.GetMethod($Method)}
      }
      
      return $res
    }
  }
  process {
    $GetConsoleWindow = get `
      Microsoft.PowerShell.ConsoleHost.dll Microsoft.PowerShell.ConsoleControl GetConsoleWindow -f
    $SendMessage = get System.dll Microsoft.Win32.UnsafeNativeMethods SendMessage
    
    [Runtime.InteropServices.HandleRef]$href = New-Object Runtime.InteropServices.HandleRef(
      (New-Object IntPtr), $GetConsoleWindow.Invoke($null, @())
    )
  }
  end {
    [void]$SendMessage.Invoke($null, @($href, 0x0111, [IntPtr]0xfff1, [IntPtr]::Zero))
  }
}
#Another possible way:
Add-Type @'
using System;
using System.Reflection;
using System.Runtime.InteropServices;

[assembly: AssemblyVersion("2.0.0.0")]
[assembly: CLSCompliant(true)]
[assembly: ComVisible(false)]

namespace Clip {
  internal static class NativeMethods {
    [DllImport("kernel32.dll")]
    internal static extern IntPtr GetConsoleWindow();
    
    [DllImport("kernel32.dll")]
    internal static extern IntPtr GlobalAlloc(UInt32 uFlags, UIntPtr dwBytes);
    
    [DllImport("kernel32.dll")]
    internal static extern IntPtr GlobalLock(IntPtr hMem);
    
    [DllImport("kernel32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    internal static extern Boolean GlobalUnlock(IntPtr hMem);
    
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    internal static extern Boolean CloseClipboard();
    
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    internal static extern Boolean EmptyClipboard();
    
    [DllImport("user32.dll")]
    internal static extern IntPtr GetOpenClipboardWindow();
    
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    internal static extern Boolean OpenClipboard(IntPtr hWndNewOwner);
    
    [DllImport("user32.dll")]
    internal static extern IntPtr SetClipboardData(UInt32 uFormat, IntPtr hMem);
  }
  
  internal static class UnsafeNativeMethods {
    [DllImport("kernel32.dll", BestFitMapping = false, ThrowOnUnmappableChar = true)]
    internal static extern IntPtr lstrcpy(IntPtr lpString1, String lpString2);
    
    [DllImport("user32.dll")]
    internal static extern IntPtr SendMessage(IntPtr hWnd, UInt32 Msg, IntPtr wParam, IntPtr lParam);
  }
  
  public sealed class Utility {
    private Utility() {}
    
    public static void Copy(String text) {
      IntPtr mem = NativeMethods.GlobalAlloc((UInt32)0x0042, (UIntPtr)(text.Length + 1));
      IntPtr lck = NativeMethods.GlobalLock(mem);
      
      UnsafeNativeMethods.lstrcpy(lck, text);
      NativeMethods.GlobalUnlock(mem);
      NativeMethods.OpenClipboard(NativeMethods.GetOpenClipboardWindow());
      NativeMethods.EmptyClipboard();
      NativeMethods.SetClipboardData((UInt32)1, mem);
      NativeMethods.CloseClipboard();
    }
    
    public static void Paste() {
      IntPtr hndl = NativeMethods.GetConsoleWindow();
      UnsafeNativeMethods.SendMessage(hndl, 0x0111, (IntPtr)0xfff1, IntPtr.Zero);
    }
  }
}
'@
[Clip.Utility]::Copy('This is a test string.')
sleep(3)
[Clip.Utility]::Paste()
#As I've said there a lot of ways of copy\paste, so...
