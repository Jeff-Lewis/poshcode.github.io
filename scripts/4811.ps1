﻿function frmMain_Show {
  Add-Type -Assembly System.Windows.Forms
  [Windows.Forms.Application]::EnableVisualStyles()
  
  $ico = [Drawing.Icon]::ExtractAssociatedIcon(($PSHome + '\powershell.exe'))

  $cur = $false #users switch
  $btn = New-Object "Windows.Forms.Button[,]" 3, 3
  
  $frmMain = New-Object Windows.Forms.Form
  $btnPlay = New-Object Windows.Forms.Button
  #
  #btnPlay
  #
  $btnPlay.Location = New-Object Drawing.Point(78, 225)
  $btnPlay.Text = "New Play"
  $btnPlay.Add_Click({
    $cur = $false
    $btn | % {$_.Text = [String]::Empty}
  })
  #
  #frmMain
  #
  $frmMain.ClientSize = New-Object Drawing.Size(231, 260)
  $frmMain.Controls.Add($btnPlay)
  $frmMain.FormBorderStyle = [Windows.Forms.FormBorderStyle]::FixedSingle
  $frmMain.Icon = $ico
  $frmMain.MainMenuStrip = $mnuMain
  $frmMain.MaximizeBox = $false
  $frmMain.MinimizeBox = $False
  $frmmain.StartPosition = [Windows.Forms.FormStartPosition]::CenterScreen
  $frmMain.Text = "Tic Tac Toe"
  $frmMain.Add_Load({
    for ($i = 0; $i -lt 3; $i++) {
      for ($j = 0; $j -lt 3; $j++) {
        $btn[$i, $j] = New-Object Windows.Forms.Button
        $btn[$i, $j].Parent = $this
        $btn[$i, $j].Left = 10 + $j * 70
        $btn[$i, $j].Top = 10 + $i * 70
        $btn[$i, $j].Size = New-Object Drawing.Size(70, 70)
        $btn[$i, $j].Font = New-Object Drawing.Font("Microsoft Sans Serif", 27, [Drawing.FontStyle]::Bold)
        $btn[$i, $j].Add_Click({
          if ([String]::IsNullOrEmpty($this.Text)) {
            switch ($cur) {
              $true {
                $this.ForeColor = [Drawing.Color]::Crimson
                $this.Text = "O"
                $cur = $false
              }
              default {
                $this.ForeColor = [Drawing.Color]::DarkGreen
                $this.Text = "X"
                $cur = $true
              }
            } #switch
          }
        }) #btnX_Click
      } #for
    } #for
  })
  
  [void]$frmmain.ShowDialog()
}

frmMain_Show
