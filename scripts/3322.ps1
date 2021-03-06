[int]$x = 0
[int]$y = 0
[int]$cX = 200
[int]$cY = 200
[int]$rad = 100
[int]$grad = 0
[float]$kfc = 0.5

$tabPag1_OnPaint= {
  $tmrTim2.Enabled = $false
  $g = $tabPag1.CreateGraphics()

  $pen = New-Object Drawing.Pen([Drawing.Brushes]::Red)
  $g.DrawRectangle($pen, [Convert]::ToInt32($cX - 100), [Convert]::ToInt32($cY - 100), $cX, $cY)
  $g.FillEllipse([Drawing.Brushes]::Red, [Convert]::ToInt32($cX + $x - 10), `
                                   [Convert]::ToInt32($cY + $y - 10), 20, 20)
  $g.Dispose()
  $tmrTim1.Enabled = $true
}

$tmrTim1_OnTick= {
  $grad += 5
  if ($gard -gt 360) { $grad -= 360 }
  $x = $rad * [Math]::Cos($grad * [Math]::PI / 180)
  $y = $kfc * $rad * [Math]::Sin($grad * [Math]::PI / 180)
  $tabPag1.Invalidate()
}

$tabPag2_OnPaint= {
  $tmrTim1.Enabled = $false
  $g = $tabPag2.CreateGraphics()

  $brush = New-Object Drawing.SolidBrush Blue
  $font = New-Object Drawing.Font("Tahoma", (12 + $val), 1)
  $msg = "Hello from GDI+!"

  [float]$center = $tabPag2.DisplayRectangle.Width / 2
  $size = $g.MeasureString($msg, $font)
  [float]$swlpos = $center - ($size.Width / 2)

  $g.DrawString($msg, $font, $brush, $swlpos, 10)
  $tmrTim2.Enabled = $true
}

$tmrTim2_OnTick= {
  $val += 5

  if ($val -ge 50) {
    $val = $null
  }

  $tabPag2.Invalidate()
}

function ShowMainWindow {
  [void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
  [void][Reflection.Assembly]::LoadWithPartialName("System.Drawing")

  [Windows.Forms.Application]::EnableVisualStyles()

  $frmMain = New-Object Windows.Forms.Form
  $tabTabs = New-Object Windows.Forms.TabControl
  $tabPag1 = New-Object Windows.Forms.TabPage
  $tabPag2 = New-Object Windows.Forms.TabPage
  $tmrTim1 = New-Object Windows.Forms.Timer
  $tmrTim2 = New-Object Windows.Forms.Timer

  #tabTabs
  $tabTabs.Controls.AddRange(@($tabPag1, $tabPag2))
  $tabTabs.Dock = "Fill"

  #tabPag1
  $tabPag1.Text = "Orbital moving"
  $tabPag1.UseVisualStyleBackColor = $true
  $tabPag1.Add_Paint($tabPag1_OnPaint)

  #tabPag2
  $tabPag2.Text = "Swelling font"
  $tabPag2.UseVisualStyleBackColor = $true
  $tabPag2.Add_Paint($tabPag2_OnPaint)

  #tmrTim1
  $tmrTim1.Interval = 100
  $tmrTim1.Add_Tick($tmrTim1_OnTick)

  #tmrTim2
  $tmrTim2.Interval = 100
  $tmrTim2.Add_Tick($tmrTim2_OnTick)

  #frmMain
  $frmMain.ClientSize = New-Object Drawing.Size(410, 430)
  $frmMain.Controls.AddRange(@($tabTabs))
  $frmMain.FormBorderStyle = "FixedSingle"
  $frmMain.MaximizeBox = $false
  $frmMain.StartPosition = "CenterScreen"
  $frmMain.Text = "Animation"

  [void]$frmMain.ShowDialog()
}

ShowMainWindow
