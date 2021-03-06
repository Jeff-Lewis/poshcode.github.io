$code = @'
using System;
using System.Runtime.InteropServices;

namespace LibWrap
{
  public class Animator
  {
    [DllImport("user32.dll")]
    public static extern bool AnimateWindow(IntPtr hWnd, uint dwTime, uint dwFlags);
  }
}
'@

function BuildAssembly {
  $cscp = New-Object Microsoft.CSharp.CSharpCodeProvider
  $cpar = New-Object CodeDom.Compiler.CompilerParameters
  $cpar.GenerateInMemory = $true
  $exec = $cscp.CompileAssemblyFromSource($cpar, $code)
}

$frmMain_OnClick= {
  BuildAssembly
  [void][LibWrap.Animator]::AnimateWindow($frmMain.Handle, 1000, 0x90000)

  $end = [DateTime]::Now.AddSeconds(3)
  while ($end -gt [DateTime]::Now) {
    Start-Sleep -m 1000
  }
  [void][LibWrap.Animator]::AnimateWindow($frmMain.Handle, 1000, 0x80000)
}

$frmMain_OnLoad= {
  $g = New-Object Drawing.Drawing2D.GraphicsPath
  $g.AddEllipse($frmMain.ClientRectangle)
  $frmMain.Region = New-Object Drawing.Region($g)
}

function ShowMainWindow {
  [void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
  [void][Reflection.Assembly]::LoadWithPartialName("System.Drawing")

  [Windows.Forms.Application]::EnableVisualStyles()

  $frmMain = New-Object Windows.Forms.Form

  #frmMain
  $frmMain.ClientSize = New-Object Drawing.Size(300, 300)
  $frmMain.MaximizeBox = $false
  $frmMain.StartPosition = "CenterScreen"
  $frmMain.Add_Click($frmMain_OnClick)
  $frmMain.Add_KeyDown( { if ($_.KeyCode -eq "Escape") { $frmMain.Close() } } )
  $frmMain.Add_Load($frmMain_OnLoad)

  [void]$frmMain.ShowDialog()
}

ShowMainWindow
