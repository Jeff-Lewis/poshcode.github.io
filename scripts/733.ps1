# Author: Doug Finke http://www.dougfinke.com/blog/
# Originally Posted: 08/13/08 (Microsoft Research .NetMap and PowerShell)
# http://www.dougfinke.com/blog/?p=465
# Modified by Steven Murawski http://www.mindofroot.com
# Updated to use the new project name "NodeXL"
# Added support for coloring the labels
# By adding a color property to the input objects, the source and target vertices
# will show with that color.  If the source vertex already exists, its color will 
# not be changed.
# Date:  12/15/2008

[Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")   | Out-Null
[Reflection.Assembly]::LoadWithPartialName("System.Drawing")   | Out-Null
[Reflection.Assembly]::Loadfrom("$pwd\Microsoft.NodeXL.Control.dll") | Out-Null

function Add-Edge($source, $target, $color)
{
    [Microsoft.NodeXL.Core.IVertex]$sourceVertex=$null
    $res=$netMapControl.Graph.Vertices.Find($source, [ref] $sourceVertex)
    if ($sourceVertex -eq $null)
    {
		$sourceVertex = $netMapControl.Graph.Vertices.Add()
		$sourceVertex.Name = $source
		$sourceVertex.SetValue("~PVLDPrimaryLabel", $source)
		if ($color -ne $null)
		{
			$sourceVertex.SetValue("~PVLDPrimaryLabelFillColor", [System.Drawing.Color]::$color )
		}
   	}

    [Microsoft.NodeXL.Core.IVertex]$targetVertex=$null
    $res=$netMapControl.Graph.Vertices.Find($target, [ref] $targetVertex)
    if ($targetVertex -eq $null)
    {
		$targetVertex = $netMapControl.Graph.Vertices.Add()
		$targetVertex.Name = $target
		$targetVertex.SetValue("~PVLDPrimaryLabel", $target)
		if ($color -ne $null)
		{
			$targetVertex.SetValue("~PVLDPrimaryLabelFillColor", [System.Drawing.Color]::$color )
		}
    }

    $edge=$netMapControl.Graph.Edges.Add($sourceVertex, $targetVertex, $true)
}

function Show-NodeXLMap($layoutType="circular") {
  Begin {
    $form = New-Object Windows.Forms.Form
    $netMapControl = New-Object Microsoft.NodeXL.Visualization.NodeXLControl
    $netMapControl.Dock = "Fill"
	$netMapControl.VertexDrawer = new-object Microsoft.NodeXL.Visualization.PerVertexWithLabelDrawer
    $netMapControl.EdgeDrawer   = new-object Microsoft.NodeXL.Visualization.PerEdgeWithLabelDrawer
    $netMapControl.BeginUpdate()
  }

  Process {
    if($_) {
      Add-Edge $_.Source $_.Target $_.Color
    }
  }

  End {
    switch -regex ($layoutType) {
       "C" { $Layout = New-Object Microsoft.NodeXL.Visualization.CircleLayout }
       "S" { $Layout = New-Object Microsoft.NodeXL.Visualization.SpiralLayout }
       "H" { $Layout = New-Object Microsoft.NodeXL.Visualization.SinusoidHorizontalLayout }
       "V" { $Layout = New-Object Microsoft.NodeXL.Visualization.SinusoidVerticalLayout }
       "G" { $Layout = New-Object Microsoft.NodeXL.Visualization.GridLayout }
       "F" { $Layout = New-Object Microsoft.NodeXL.Visualization.FruchtermanReingoldLayout }
       "R" { $Layout = New-Object Microsoft.NodeXL.Visualization.RandomLayout }
       "Y" { $Layout = New-Object Microsoft.NodeXL.Visualization.SugiyamaLayout }
    }

    $netMapControl.Layout=$layout
    $netMapControl.EndUpdate()
    $form.Controls.Add($NetMapControl)
    $form.WindowState="Maximized"
    #$form.Size = New-Object Drawing.Size @(1000, 600)
    $form.ShowDialog() | out-null
	
  }
}
