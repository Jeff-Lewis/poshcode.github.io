##
## Author   : Roman Kuzmin
## Synopsis : Resize console window/buffer using arrow keys
##

function Size($w, $h)
{
    New-Object System.Management.Automation.Host.Size($w, $h)
}

function resize()
{
Write-Host '[Arrows] resize  [Esc] exit ...'
$ErrorActionPreference = 'SilentlyContinue'
for($ui = $Host.UI.RawUI;;) {
    $b = $ui.BufferSize
    $w = $ui.WindowSize
    switch($ui.ReadKey(6).VirtualKeyCode) {
        37 {
            $w = Size ($w.width - 1) $w.height
            $ui.WindowSize = $w
            $ui.BufferSize = Size $w.width $b.height
            break
        }
        39 {
            $w = Size ($w.width + 1) $w.height
            $ui.BufferSize = Size $w.width $b.height
            $ui.WindowSize = $w
            break
        }
        38 {
            $ui.WindowSize = Size $w.width ($w.height - 1)
            break
        }
        40 {
            $w = Size $w.width ($w.height + 1)
            if ($w.height -gt $b.height) {
                $ui.BufferSize = Size $b.width $w.height
            }
            $ui.WindowSize = $w
            break
        }
        27 {
            return
        }
    }
  }
}
