#Follow me on twitter @gregzakharov

$btnBut1_Click= {
  $txtBox1.Text = [String]::Empty
  foreach ($pco in (Get-Help $cboCbo1.SelectedItem)) {
    $pco.Description | % {$txtBox1.Text = $_.Text}
  }
}

$btnBut2_Click= {
  $txtBox2.Text = [String]::Empty
  $txtBox2.Text = [IO.File]::ReadAllText($arr[$cboCbo2.SelectedIndex], [Text.Encoding]::Default)
}

function frmMain_Show {
  Add-Type -AssemblyName System.Windows.Forms
  [Windows.Forms.Application]::EnableVisualStyles()
  
  $ico = [Drawing.Icon]::ExtractAssociatedIcon(($PSHome + '\powershell.exe'))
  $arr = gci ($PSHome + '\' + (Get-Culture).TwoLetterISOLanguageName) -fi *.txt | % {$_.FullName}
  
  $frmMain = New-Object Windows.Forms.Form
  $tabCtrl = New-Object Windows.Forms.TabControl
  $tpPage1 = New-Object Windows.Forms.TabPage
  $tpPage2 = New-Object Windows.Forms.TabPage
  $lblLab1 = New-Object Windows.Forms.Label
  $lblLab2 = New-Object Windows.Forms.Label
  $cboCbo1 = New-Object Windows.Forms.ComboBox
  $cboCbo2 = New-Object Windows.Forms.ComboBox
  $btnBut1 = New-Object Windows.Forms.Button
  $btnBut2 = New-Object Windows.Forms.Button
  $txtBox1 = New-Object Windows.Forms.TextBox
  $txtBox2 = New-Object Windows.Forms.TextBox
  #
  #tabCtrl
  #
  $tabCtrl.Controls.AddRange(@($tpPage1, $tpPage2))
  $tabCtrl.Dock = "Fill"
  #
  #tpPage1
  #
  $tpPage1.Controls.AddRange(@($lblLab1, $cboCbo1, $btnBut1, $txtBox1))
  $tpPage1.Text = "Cmdlet Pages"
  $tpPage1.UseVisualStyleBackColor = $true
  #
  #tpPage2
  #
  $tpPage2.Controls.AddRange(@($lblLab2, $cboCbo2, $btnBut2, $txtBox2))
  $tpPage2.Text = "About Pages"
  $tpPage2.UseVisualStyleBackColor = $true
  #
  #lblLab1
  #
  $lblLab1.Location = New-Object Drawing.Point(7, 10)
  $lblLab1.Size = New-Object Drawing.Size(85, 17)
  $lblLab1.Text = "Choose Cmdlet:"
  #
  #lblLab2
  #
  $lblLab2.Location = New-Object Drawing.Point(7, 10)
  $lblLab2.Size = New-Object Drawing.Size(85, 17)
  $lblLab2.Text = "Choose Page:"
  #
  #cboCbo1
  #
  $cboCbo1.Items.AddRange((Get-Command | ? {$_.CommandType -eq 'Cmdlet'}))
  $cboCbo1.Location = New-Object Drawing.Point(92, 7)
  $cboCbo1.SelectedIndex = (Get-Random -max ($cboCbo1.Items.Count - 1))
  $cboCbo1.Width = 190
  #
  #cboCbo2
  #
  $cboCbo2.Items.AddRange(($arr | % {Split-Path -leaf $_}))
  $cboCbo2.Location = New-Object Drawing.Point(92, 7)
  $cboCbo2.SelectedIndex = (Get-Random -max ($arr.Length - 1))
  $cboCbo2.Width = 270
  #
  #btnBut1
  #
  $btnBut1.Location = New-Object Drawing.Point(287, 6)
  $btnBut1.Text = "Read"
  $btnBut1.Add_Click($btnBut1_Click)
  #
  #btnBut2
  #
  $btnBut2.Location = New-Object Drawing.Point(367, 6)
  $btnBut2.Text = "Read"
  $btnBut2.Add_Click($btnBut2_Click)
  #
  #txtBox1
  #
  $txtBox1.BackColor = [Drawing.Color]::DarkBlue
  $txtBox1.Font = New-Object Drawing.Font('Tahoma', 10)
  $txtBox1.ForeColor = [Drawing.Color]::LightGray
  $txtBox1.Location = New-Object Drawing.Point(7, 33)
  $txtBox1.Multiline = $true
  $txtBox1.ScrollBars = "Vertical"
  $txtBox1.Size = New-Object Drawing.Size(547, 300)
  #
  #txtBox2
  #
  $txtBox2.BackColor = [Drawing.Color]::DarkBlue
  $txtBox2.Font = New-Object Drawing.Font('Tahoma', 10)
  $txtBox2.ForeColor = [Drawing.Color]::LightGray
  $txtBox2.Location = New-Object Drawing.Point(7, 33)
  $txtBox2.Multiline = $true
  $txtBox2.ScrollBars = "Vertical"
  $txtBox2.Size = New-Object Drawing.Size(547, 300)
  #
  #frmMain
  #
  $frmMain.ClientSize = New-Object Drawing.Size(570, 370)
  $frmMain.Controls.AddRange(@($tabCtrl))
  $frmMain.FormBorderStyle = "FixedSingle"
  $frmMain.Icon = $ico
  $frmMain.MaximizeBox = $false
  $frmMain.StartPosition = "CenterScreen"
  $frmMain.Text = "Quick Guide"
  
  [void]$frmMain.ShowDialog()
}

frmMain_Show
