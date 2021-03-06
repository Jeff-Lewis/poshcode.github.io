#requires -version 2.0
function Get-ItemsList {
  $lvItems.Items.Clear()
  
  $pek = New-Object Reflection.PortableExecutableKinds
  $ifm = New-Object Reflection.ImageFileMachine
  
  gci ([Regex]"(?<=file:///)(.*)(?=GAC.*)").Match(
    ([AppDomain]::CurrentDomain.GetAssemblies()[0].Evidence | select Value | ? {
      $_.Value -ne $null
    }
  ).Value).Value | % {
    if ($_ -notlike 't*mp') {
      gci ($_.FullName + '\*\*\*') | % {
        try {
          if ($_.FullName -like '*.exe') { return }
          $mod = [Reflection.Assembly]::ReflectionOnlyLoadFrom(
            $_.FullName
          )
          $asm = $mod.FullName.Split(',')
          $itm = $lvItems.Items.Add($asm[0], 0)
          $itm.SubItems.Add($asm[1].Split('=')[1])
          $itm.SubItems.Add($asm[2].Split('=')[1])
          $itm.SubItems.Add($asm[3].Split('=')[1])
          $mod.ManifestModule.GetPEKind([ref]$pek, [ref]$ifm)
          $itm.SubItems.Add(($pek -as [String]))
          $itm.SubItems.Add($_.FullName)
        }
        catch {}
      }
    } #if
  } #foreach
  $lvItems.AutoResizeColumns([Windows.Forms.ColumnHeaderAutoResizeStyle]::ColumnContent)
  Get-ItemsNumber
}

function Get-ItemsNumber {
  $sbLabel.Text = $lvItems.Items.Count.ToString() + ' item(s)'
}

function frmMain_Show {
  Add-Type -AssemblyName System.Windows.Forms
  [Windows.Forms.Application]::EnableVisualStyles()
  
  $ico = [Drawing.Icon]::ExtractAssociatedIcon(($PSHome + '\powershell.exe'))
  
  $frmMain = New-Object Windows.Forms.Form
  $mnuMain = New-Object Windows.Forms.MenuStrip
  $mnuFile = New-Object Windows.Forms.ToolStripMenuItem
  $mnuScan = New-Object Windows.Forms.ToolStripMenuItem
  $mnuExit = New-Object Windows.Forms.ToolStripMenuItem
  $mnuView = New-Object Windows.Forms.ToolStripMenuItem
  $mnuHelp = New-Object Windows.Forms.ToolStripMenuItem
  $mnuInfo = New-Object Windows.Forms.ToolStripMenuItem
  $lvItems = New-Object Windows.Forms.ListView
  $chCol_1 = New-Object Windows.Forms.ColumnHeader
  $chCol_2 = New-Object Windows.Forms.ColumnHeader
  $chCol_3 = New-Object Windows.Forms.ColumnHeader
  $chCol_4 = New-Object Windows.Forms.ColumnHeader
  $chCol_5 = New-Object Windows.Forms.ColumnHeader
  $chCol_6 = New-Object Windows.Forms.ColumnHeader
  $imgList = New-Object Windows.Forms.ImageList
  $sbStrip = New-Object Windows.Forms.StatusStrip
  $sbLabel = New-Object Windows.Forms.ToolStripStatusLabel
  #
  #common
  #
  $mnuMain.Items.AddRange(@($mnuFile, $mnuHelp))
  $chCol_1.Text = "Assembly Name"
  $chCol_2.Text = "Version"
  $chCol_3.Text = "Culture"
  $chCol_4.Text = "Public Key Token"
  $chCol_5.Text = "Kind"
  $chCol_6.Text = "Full Path"
  $sbStrip.Items.AddRange(@($sbLabel))
  $sbLabel.AutoSize = $true
  $imgList.Images.Add($ico.ToBitmap())
  #
  #mnuFile
  #
  $mnuFile.DropDownItems.AddRange(@($mnuScan, $mnuExit))
  $mnuFile.Text = "&File"
  #
  #mnuScan
  #
  $mnuScan.ShortcutKeys = [Windows.Forms.Keys]::F5
  $mnuScan.Text = "&Scan"
  $mnuScan.Add_Click({Get-ItemsList})
  #
  #mnuExit
  #
  $mnuExit.ShortcutKeys = [Windows.Forms.Keys]::Control, [Windows.Forms.Keys]::X
  $mnuExit.Text = "E&xit"
  $mnuExit.Add_Click({$frmMain.Close()})
  #
  #mnuHelp
  #
  $mnuHelp.DropDownItems.AddRange(@($mnuInfo))
  $mnuHelp.Text = "&Help"
  #
  #mnuInfo
  #
  $mnuInfo.Text = "About..."
  $mnuInfo.Add_Click({frmInfo_Show})
  #
  #lvItems
  #
  $lvItems.AllowColumnReorder = $true
  $lvItems.Columns.AddRange(@($chCol_1, $chCol_2, $chCol_3, $chCol_4, $chCol_5, $chCol_6))
  $lvItems.Dock = [Windows.Forms.DockStyle]::Fill
  $lvItems.SmallImageList = $imgList
  $lvItems.Sorting = [Windows.Forms.SortOrder]::Ascending
  $lvItems.View = [Windows.Forms.View]::Details
  #
  #frmMain
  #
  $frmMain.ClientSize = New-Object Drawing.Size(570, 320)
  $frmMain.Controls.AddRange(@($lvItems, $sbStrip, $mnuMain))
  $frmMain.Icon = $ico
  $frmMain.MainMenuStrip = $mnuMain
  $frmMain.StartPosition = [Windows.Forms.FormStartPosition]::CenterScreen
  $frmMain.Text = "GACView"
  $frmMain.Add_Load({Get-ItemsNumber})
  
  [void]$frmMain.ShowDialog()
}

function frmInfo_Show {
  $frmInfo = New-Object Windows.Forms.Form
  $pbImage = New-Object Windows.Forms.PictureBox
  $lblName = New-Object Windows.Forms.Label
  $lblCopy = New-Object Windows.Forms.Label
  $btnExit = New-Object Windows.Forms.Button
  #
  #pbImage
  #
  $pbImage.Image = $ico.ToBitmap()
  $pbImage.Location = New-Object Drawing.Point(16, 16)
  $pbImage.Size = New-Object Drawing.Size(32, 32)
  $pbImage.SizeMode = [Windows.Forms.PictureBoxSizeMode]::StretchImage
  #
  #lblName
  #
  $lblName.Font = New-Object Drawing.Font("Microsoft Sans Serif", 8.5, [Drawing.FontStyle]::Bold)
  $lblName.Location = New-Object Drawing.Point(53, 19)
  $lblName.Size = New-Object Drawing.Size(360, 18)
  $lblName.Text = "GACView v1.01"
  #
  #lblCopy
  #
  $lblCopy.Location = New-Object Drawing.Point(67, 37)
  $lblCopy.Size = New-Object Drawing.Size(360, 23)
  $lblCopy.Text = "Copyright (C) 2014 greg zakharov"
  #
  #btnExit
  #
  $btnExit.Location = New-Object Drawing.Point(135, 67)
  $btnExit.Text = "OK"
  #
  #frmInfo
  #
  $frmInfo.AcceptButton = $btnExit
  $frmInfo.CancelButton = $btnExit
  $frmInfo.ClientSize = New-Object Drawing.Size(350, 110)
  $frmInfo.ControlBox = $false
  $frmInfo.Controls.AddRange(@($pbImage, $lblName, $lblCopy, $btnExit))
  $frmInfo.FormBorderStyle = [Windows.Forms.FormBorderStyle]::FixedSingle
  $frmInfo.ShowInTaskBar = $false
  $frmInfo.StartPosition = [Windows.Forms.FormStartPosition]::CenterParent
  $frmInfo.Text = "About..."
  $frmInfo.Add_Load($frmInfo_Load)

  [void]$frmInfo.ShowDialog()
}

frmMain_Show
