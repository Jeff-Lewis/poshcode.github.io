[CmdletBinding()]
param (
    [string]$InsideColor = 'White',
    [string]$OutsideColor = 'Transparent',
    [int]$BorderThickness = 5
)

Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName WindowsBase

# script requires STA... let us check it.
if ([Threading.Thread]::CurrentThread.GetApartmentState() -eq 'MTA') {
    Write-Warning @'
This script is using controls, that require STA mode. You can:
* Try to run 'PowerShell -STA' and launch the script again
* Run it from PowerShell ISE where STA is default mode.
See you than! ;)
'@
    exit
}

Function New-TunnelGradientBrush {
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, HelpMessage = 'Color that will fill interior of the brush')]
    [System.Windows.Media.Color]$InsideColor,
    [Parameter(Mandatory = $true, HelpMessage = 'Color that will be used for border of the brush')]
    [System.Windows.Media.Color]$OutsideColor,
    [Parameter(Mandatory = $true, HelpMessage = 'Size of border as part of width, acceptable values: 0 - 0.49')]
    [ValidateRange(0,49)]
    [int]$BorderThickness
)
    Set-StrictMode -Version Latest
    # Prepare few points that will be necessary later in the process...
    
    $Left = New-Object Windows.Point 0, 0.5
    $Right = New-Object Windows.Point 1, 0.5
    $Top = New-Object Windows.Point 0.5, 0
    $Bottom = New-Object Windows.Point 0.5, 1

    $LeftTop = New-Object Windows.Point 0, 0
    $LeftBottom = New-Object Windows.Point 0, 1
    $RightTop = New-Object Windows.Point 1, 0
    $RightBottom = New-Object Windows.Point 1, 1
    
    # Now some values that relate to $BorderTickness selected.
    
    [double]$StartOffset = $BorderThickness / 100
    [double]$EndOffset = - ($BorderThickness / 100) + 1
    $NarrowSize = 100 - 2 * $BorderThickness
    $CornerSize = $BorderThickness
 
    # Build brushes that will be used to create our final brush (VisualBrush)
    
    $GradientStops = New-Object Windows.Media.GradientStopCollection
    @{ 0 = $OutsideColor
        $StartOffset = $InsideColor
        $EndOffset = $InsideColor
        1 = $OutsideColor
    }.GetEnumerator() | Foreach { $GradientStops.Add($(New-Object Windows.Media.GradientStop $_.Value, $_.Name)) }

    $GradientStopsRadial = New-Object Windows.Media.GradientStopCollection
    @{ 1 = $OutsideColor
       0 = $InsideColor
    }.GetEnumerator() | Foreach { $GradientStopsRadial.Add($(New-Object Windows.Media.GradientStop $_.Value, $_.Name)) }
    
    
    $BrushLeftRight = New-Object Windows.Media.LinearGradientBrush -Property @{ 
        StartPoint = $Left 
        EndPoint = $Right 
        GradientStops = $GradientStops
    }

    $BrushTopBottom = New-Object Windows.Media.LinearGradientBrush -Property @{ 
        StartPoint = $Top
        EndPoint = $Bottom 
        GradientStops = $GradientStops
    }
    
    $CommonProperty = @{
        RadiusX = 1 
        RadiusY = 1 
        GradientStops = $GradientStopsRadial
    }

    $BrushLeftTop = New-Object Windows.Media.RadialGradientBrush -Property (@{ 
        Center = $RightBottom 
        GradientOrigin = $RightBottom 
    } + $CommonProperty)

    $BrushLeftBottom = New-Object Windows.Media.RadialGradientBrush -Property (@{ 
        Center = $RightTop 
        GradientOrigin = $RightTop 
    } + $CommonProperty)
        
    $BrushRightTop = New-Object Windows.Media.RadialGradientBrush -Property (@{ 
        Center = $LeftBottom 
        GradientOrigin = $LeftBottom
    } + $CommonProperty)

    $BrushRightBottom = New-Object Windows.Media.RadialGradientBrush -Property (@{ 
        Center = $LeftTop 
        GradientOrigin = $LeftTop
    } + $CommonProperty)
    
    # Create Visual Brush Elements (StackPanels).

    $Horizontal = New-Object Windows.Controls.StackPanel -Property @{
        Background = $BrushLeftRight 
        Width = 100 
        Height = $NarrowSize
    }
    
    $Vertical = New-Object Windows.Controls.StackPanel -Property @{
        Background = $BrushTopBottom 
        Width = $NarrowSize 
        Height = 100
    }
    
    $Corners = @{
        Width = $CornerSize 
        Height = $CornerSize
    }
    
    $TopLeft = New-Object Windows.Controls.StackPanel -Property (@{
        Background = $BrushLeftTop 
        VerticalAlignment = 'Top' 
        HorizontalAlignment = 'Left'
    } + $Corners)

    $BottomLeft = New-Object Windows.Controls.StackPanel -Property (@{
        Background = $BrushLeftBottom 
        VerticalAlignment = 'Bottom' 
        HorizontalAlignment = 'Left'
    } + $Corners)

    $TopRight = New-Object Windows.Controls.StackPanel -Property (@{
        Background = $BrushRightTop 
        VerticalAlignment = 'Top' 
        HorizontalAlignment = 'Right'
    } + $Corners)

    $BottomRight = New-Object Windows.Controls.StackPanel -Property (@{
        Background = $BrushRightBottom 
        VerticalAlignment = 'Bottom' 
        HorizontalAlignment = 'Right'
    } + $Corners)
    
    # Grid that will hold all panels and will be Visual for VisualBrush

    $Grid = New-Object Windows.Controls.Grid
    foreach ($Control in $Vertical, $Horizontal, $BottomLeft, $BottomRight, $TopLeft, $TopRight) {
        $Grid.Children.Add($Control) | Out-Null
    }

    # Send visualBrush to pipe... at last! :)
    New-Object System.Windows.Media.VisualBrush $Grid    
}

# Sample...
try {
    $Brush = New-TunnelGradientBrush -InsideColor $InsideColor -OutsideColor $OutsideColor -BorderThickness $BorderThickness
} catch {
    Write-Host "Try some valid values. -Verbose for more."
    Write-Verbose $_
    exit
}

$Window = New-Object Windows.Window -Property @{
    BackGround = $Brush
    Width = 200
    Height = 200
    WindowStyle = 'None'
    AllowsTransparency = $True
}

$Window.Add_MouseLeftButtonDown({ $this.DragMove() })
$Window.Add_MouseRightButtonDown({ $this.Close() })
$Window.ShowDialog() | Out-Null
