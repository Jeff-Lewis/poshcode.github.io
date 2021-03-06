function Get-WifiNetwork {
    end {
        netsh wlan sh net mode=bssid | % -process {
            if ($_ -match '^SSID (\d+) : (.*)$') {
                $current = @{}
                $networks += $current
                $current.Index = $matches[1].trim()
                $current.SSID = $matches[2].trim()
            } else {
                if ($_ -match '^\s+(BSSID) \d{1,}\s+:\s+(.*)\s*$') {
                    if ($current[$matches[1].trim()].Length -gt 0) {
                        $current = @{}
                        $current.Index = $networks.Item($networks.Count-1).Index
                        $current.SSID = $networks.Item($networks.Count-1).SSID
                        $current['Network type'] = $networks.Item($networks.Count-1)['Network type']
                        $current['Authentication'] = $networks.Item($networks.Count-1)['Authentication']
                        $current['Encryption'] = $networks.Item($networks.Count-1)['Encryption']
                        $current['MaxSignal'] = $networks.Item($networks.Count-1)['MaxSignal']
                        $networks += $current
                    }
                    $current[$matches[1].trim()] = $matches[2].trim()
                }
                elseif ( $_ -match '^\s+(Signal)\s+:\s+(.*)\s*$' ) {
                    $current[$matches[1].trim()] = $matches[2].trim();
                    $current['MaxSignal'] = $matches[2].trim();
                    foreach($network in $networks) {
                        if ( $current.Index -eq $network.Index -and $current['MaxSignal'] -gt $network['MaxSignal'] ) {
                            $network['MaxSignal'] = $current['MaxSignal'];
                        } elseif ( $current.Index -eq $network.Index -and $current['MaxSignal'] -lt $network['MaxSignal'] ) {
                            $current['MaxSignal'] = $network['MaxSignal'];
                        }
                    }
                }
                elseif ($_ -match '^\s+(.*)\s+:\s+(.*)\s*$') {
                    $current[$matches[1].trim()] = $matches[2].trim()
                }
            }
        } -begin { $networks = @() } -end { $networks | % { new-object psobject -property $_ } }
    }
}

PS> Get-WifiNetwork| select index, ssid, bssid, MaxSignal, signal, 'radio type',Authentication, Encryption | sort MaxSignal, signal -desc | select index, ssid, bssid, signal, 'radio type',Authentication, Encryption | ft -auto
