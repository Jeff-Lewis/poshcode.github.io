$nul = "<NULL>"

function Get-AssembliesTree {
  [AppDomain]::CurrentDomain.GetAssemblies() | % {
    $nod = New-Object Windows.Forms.TreeNode
    $nod.Text = $_.GetName().Name
    $nod.Tag = $_

    $tvAssem.Nodes.Add($nod)
    $nod.Nodes.Add($nul)
  }
}

function Add-Types {
  $_.Node.Nodes.Clear()

  try {
    foreach ($t in $_.Node.Tag.GetTypes()) {
      if ($t.IsPublic) {
        $node = $_.Node.Nodes.Add($t.FullName)
        $node.Tag = $t
        $node.Nodes.Add($nul)
      }
    }
  }
  catch {}
}

function Add-Members {
  try {
    foreach ($m in $_.Node.Tag.GetMembers()) {
      $node = $_.Node.Nodes.Add($m.Name)
      $node.Tag = $m.MemberType
    }
  }
  catch {}
}

$tvAssem_BeforeExpand= {
  Add-Types
  Add-Members
}

function frmMain_Show {
  Add-Type -AssemblyName System.Windows.Forms
  [Windows.Forms.Application]::EnableVisualStyles()

  $ico = [Drawing.Icon]::ExtractAssociatedIcon((
    [Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory() + '\MSBuild.exe'
  ))

  $frmMain = New-Object Windows.Forms.Form
  $tvAssem = New-Object Windows.Forms.TreeView
  $sbPanel = New-Object Windows.Forms.StatusBar
  #
  #tvAssem
  #
  $tvAssem.Dock = "Fill"
  $tvAssem.Sorted = $true
  $tvAssem.Add_AfterSelect({$sbPanel.Text = $_.Node.Tag})
  $tvAssem.Add_BeforeExpand($tvAssem_BeforeExpand)
  #
  #sbPanel
  #
  $sbPanel.Font = New-Object Drawing.Font("Microsoft Sans Serif", 9, [Drawing.FontStyle]::Bold)
  $sbPanel.SizingGrip = $false
  #
  #frmMain
  #
  $frmMain.ClientSize = New-Object Drawing.Size(590, 550)
  $frmMain.Controls.AddRange(@($tvAssem, $sbPanel))
  $frmMain.FormBorderStyle = "FixedSingle"
  $frmMain.Icon = $ico
  $frmMain.StartPosition = "CenterScreen"
  $frmMain.Text = "Reflection"
  $frmMain.Add_Load({Get-AssembliesTree})

  [void]$frmMain.ShowDialog()
}

frmMain_Show
