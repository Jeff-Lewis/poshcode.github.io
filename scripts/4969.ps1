#requires -version 2.0
Set-Alias ohv Out-HexView

function Out-HexView {
  <#
    .EXAMPLE
        PS C:\>ohv foo
        Dumps all bytes.
    .EXAMPLE
        PS C:\>ohv foo -b 750 -o 25
        Process 750 bytes (25 bytes is offset).
    .NOTES
        Author: greg zakharov
  #>
  [CmdletBinding(DefaultParameterSetName="FileName", SupportsShouldProcess=$true)]
  param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateScript({Test-Path $_})]
    [String]$FileName,
    
    [Parameter(Position=1)]
    [Alias("b")]
    [UInt32]$BytesToProcess,
    
    [Parameter(Position=2)]
    [Alias("o")]
    [UInt32]$BytesOffset
  )
  
  begin {
    function frmMain_Show([String]$file, [Byte[]]$bytes) {
      Add-Type -AssemblyName System.Design, System.Windows.Forms
      [Windows.Forms.Application]::EnableVisualStyles()
      
      $ico = [Drawing.Icon]::ExtractAssociatedIcon(($PSHome + '\powershell.exe'))
      
      $frmMain = New-Object Windows.Forms.Form
      $tsStrip = New-Object Windows.Forms.ToolStrip
      $tsLabel = New-Object Windows.Forms.ToolStripLabel
      $tsCombo = New-Object Windows.Forms.ToolStripComboBox
      $bvBytes = New-Object ComponentModel.Design.ByteViewer
      $sbStrip = New-Object Windows.Forms.StatusStrip
      $sblabel = New-Object Windows.Forms.ToolStripStatusLabel
      #
      #common
      #
      $tsStrip.Items.AddRange(@($tsLabel, $tsCombo))
      $tsLabel.Text = "Display Mode:"
      #
      #tsCombo
      #
      [Enum]::GetValues([ComponentModel.Design.DisplayMode]) | % {
        [void]$tsCombo.Items.Add($_)
      }
      $tsCombo.SelectedIndex = 0
      $tsCombo.Add_SelectedIndexChanged({
        if ($bvBytes.GetBytes() -ne $null) {
          $bvBytes.SetDisplayMode([ComponentModel.Design.DisplayMode]$tsCombo.SelectedItem)
        }
      })
      #
      #bvBytes
      #
      $bvBytes.Dock = [Windows.Forms.DockStyle]::Fill
      $bvBytes.SetBytes($bytes)
      #
      #sbStrip
      #
      $sbStrip.Items.AddRange(@($sbLabel))
      $sbStrip.SizingGrip = $false
      #
      #sbLabel
      #
      $sbLabel.AutoSize = $true
      $sbLabel.ForeColor = [Drawing.Color]::DarkCyan
      $sbLabel.Text = $file
      #
      #frmMain
      #
      $frmMain.ClientSize = New-Object Drawing.Size(633, 437)
      $frmMain.Controls.AddRange(@($bvBytes, $sbStrip, $tsStrip))
      $frmMain.FormBorderStyle = [Windows.Forms.FormBorderStyle]::FixedSingle
      $frmMain.Icon = $ico
      $frmMain.MaximizeBox = $false
      $frmMain.MinimizeBox = $false
      $frmMain.StartPosition = [Windows.Forms.FormStartPosition]::CenterScreen
      $frmMain.Text = $PSCmdlet.CommandRuntime
      
      [void]$frmMain.ShowDialog()
    }
  }
  process {
    if ($PSCmdlet.ShouldProcess($FileName, "Show hexdump popup")) {
      try {
        $FileName = cvpa $FileName
        $fs = [IO.File]::OpenRead($FileName)
        #offset
        if ($BytesOffset -ge $fs.Length) {
          throw (New-Object IO.IOException("Out of stream."))
        }
        else {[void]$fs.Seek($BytesOffset, [IO.SeekOrigin]::Begin)}
        #bytes to process
        if ($BytesToProcess -gt 0) {
          $buf = New-Object "Byte[]" ($fs.Length - ($fs.Length - $BytesToProcess))
        }
        else {$buf = New-Object "Byte[]" $fs.Length}
        [void]$fs.Read($buf, 0, $buf.Length)
        
        frmMain_Show $FileName $buf
      }
      catch [IO.IOException] {Write-Host $_.Exception.Message -fo Red}
      finally {
        if ($fs -ne $null) {$fs.Close()}
      }
    } #if
  }
  end {}
}
