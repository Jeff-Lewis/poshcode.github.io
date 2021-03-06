function Show-CPU {
  <#
    .EXAMPLE
        Show-CPU

        Monitors CPU and shows a green graph until you press a key.

    .EXAMPLE
        Show-CPU -Color Red

        Sets red color for graph
  #>
  param(
    # Set the color for the graph
    [Parameter(Position=1)]
    [ConsoleColor]$Color = 'Green',

    [ValidateRange(100,30000)]
    [int]$SampleFrequencyMs = 500
  )
  
  begin {
    $Label = "CPU Usage"
    $pc = New-Object Diagnostics.PerformanceCounter("Processor", "% Processor Time", "_Total")

    $raw = $host.UI.RawUI
    $old = $raw.WindowPosition
    $con = $raw.WindowSize
    $rec = New-Object Management.Automation.Host.Rectangle $old.X, $old.Y, `
                                        $raw.BufferSize.Width, ($old.Y + 25)
    $buf = $raw.GetBufferContents($rec)
    
    function hbar([int]$left, [int]$top, [int]$right, [ConsoleColor]$color) {
      $pos = $old
      $pos.X += $left
      $pos.Y += $top
      $row = $raw.NewBufferCellArray(@(' ' * ($right-$left)), $color, $color)
      $raw.SetBufferContents($pos, $row)
    }
    
    function msg([int]$left, [int]$top, [String]$text, [ConsoleColor]$foreground, [ConsoleColor]$background) {
      $pos = $old
      $pos.X += $left
      $pos.Y += $top
      $row = $raw.NewBufferCellArray(@($text), $foreground, $background)
      $raw.SetBufferContents($pos, $row)
    }

    # clear the key buffer
    sleep -m 250
    while ($Host.UI.RawUI.KeyAvailable) {
      $null = $Host.UI.RawUI.ReadKey()
    }

  }
  end {
    # clear a bar
    hbar 0 1 ($con.Width + 1) $Host.UI.RawUI.BackgroundColor
    # draw a label
    msg 0 1 $Label 'Gray' 'DarkYellow'
    # initialize
    $Width = ($con.Width + 1) - $Label.Length
    $Next = [Math]::Round($pc.NextValue() * 100 / $Width) + $Label.Length

    while (!$Host.UI.RawUI.KeyAvailable) {      
      $Prev = $Next
      $Next = [Math]::Round($pc.NextValue() * 100 / $Width) + $Label.Length
      if($Next -gt $Prev) {
        # bigger value, add to the bar
        hbar $Prev 1 $Next $Color
      } elseif($Prev -gt $Next) {
        # smaller value, clear the bar
        hbar $Next 1 $Prev "Black" # $Host.UI.RawUI.BackgroundColor
      }
      sleep -m $SampleFrequencyMs
    }

    $raw.SetBufferContents($old, $buf)
  }



}

