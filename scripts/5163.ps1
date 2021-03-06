<#
.SYNOPSIS
    Onkyo home theatre receiver controller
.DESCRIPTION
    Library to discover Onkyo network connected home theatre receiver and then send remote control commands to change
    settings such as volume but also query current settings. Uses the Integra Serial Communication Protocol (ISCP).
    Tested with Onkyo TX-NR509. As of now this can only work with one receiver at a time however extending to multiple
    receivers should not be that hard. Please contact the author if you have need for multiple receivers or any other requirements.
    
    Complete Integra Serial Communication Protocol is documented here http://blog.siewert.net/files/ISCP%20AV%20Receiver%20v124-1.xls

    Combine this module with a simple PowerShell RESTful server http://poshcode.org/4073 and some HTML/Javascript and you can quickly
    build a nice HTML interface to your Onkyo receiver that can be used from any device including PC, Mac and mobile devices. Very
    useful when you want advanced commands such as dynamic range control that are not available in the official app
.NOTES
    Author: Parul Jain paruljain@hotmail.com
    Version: 1.0, May 16th, 2014
    Prerequisites: PowerShell v2.0 or higher
.EXAMPLE
    $receiver = New-OnkyoReceiver
    for ($i=0; $i -lt 6; $i++) { if ($receiver.Discover()) { break } }
    if (!$receiver.connected) { throw 'Unable to discover and connect to receiver' }
    $receiver.Send('pwr01') #Power on
    $receiver.Send('mvl' + (20 | Convert-ToHex)) #Set master volume to 20
    $receiver.Send('sli24') #Select FM radio
    $receiver.Send('tun10670') #Tune to 106.7 (NYC area Lite FM)
    if ($receiver.Send('mvl') -match 'MVL(\d+)') { 'The current volume is ' + ($matches[1] | Convert-ToDec) }
    $receiver.Disconnect()
#>

function Convert-ToHex {
    Process {
        "{0:X2}" -f $_
    }
}

function Convert-ToDec {
    Process {
        [Convert]::ToInt32($_, 16).ToString()
    }
}

function New-OnkyoReceiver {
    $receiver = New-Object PSObject
    $receiver | Add-Member -MemberType NoteProperty -Name Name -Value ''
    $receiver | Add-Member -MemberType NoteProperty -Name IPAddress -Value ''
    $receiver | Add-Member -MemberType NoteProperty -Name Port -Value 60128
    $receiver | Add-Member -MemberType NoteProperty -Name Connected -Value $false
    $receiver | Add-Member -MemberType NoteProperty -Name Stream -Value $null

    $receiver | Add-Member -MemberType ScriptMethod -Name Discover -Value {
        $udpClient = New-Object System.Net.Sockets.UdpClient
        $udpClient.EnableBroadcast = $true
        $udpClient.Client.ReceiveTimeout = 1000 # milliseconds
        $udpClient.Client.ExclusiveAddressUse = $false
        $ep = New-Object Net.IPEndPoint($([Net.IPAddress]::Any, 0))
        [byte[]]$packet = (73,83,67,80,0,0,0,16,0,0,0,11,1,0,0,0,33,120,69,67,78,81,83,84,78,13,10)
        $udpClient.Send($packet, $packet.Length, '255.255.255.255', 60128) | out-null
        $udpClient.Send($packet, $packet.Length, '255.255.255.255', 60128) | out-null

        #Wait-Job -Job $job | out-null
        
        try {
            $response = $udpClient.Receive([Ref]$ep)
            # Get the command length. We need to convert to little-endian before conversion to Int32
            $cmdLength = [BitConverter]::ToInt32($response[11..8], 0)

            $this.Name = [System.Text.Encoding]::ASCII.GetString($response[24..(13 + $cmdLength)]).split('/')[0]
            $this.IPAddress = $ep.Address.IPAddressToString
            $this.Port = $ep.Port
            $this.Connect()
        } catch { $false }
    }

    $receiver | Add-Member -MemberType ScriptMethod -Name Connect -Value {
        if ($this.Connected) { $true; return }
        if (!$this.IPAddress) { $false; return } # IPAddress must be set before calling connect()
        try { $socket = New-Object System.Net.Sockets.TcpClient($this.IPAddress, $this.Port) }
        catch { $false; return } #Unable to connect: bad IP and/or Port
        $this.Connected = $true
        $this.Stream = $socket.GetStream()
        $this.Stream.ReadTimeout = 1000
        $this.Stream.WriteTimeout = 1000
        $this.send('MVL') | out-null # workaround for strange behaviour when first command is sent
        $true
    }

    $receiver | Add-Member -MemberType ScriptMethod -Name Disconnect -Value {
        if (!$this.Connected) { return } # Already disconnected, do nothing
        $this.Stream.Close()
        $this.Connected = $false
    }

    $receiver | Add-Member -MemberType ScriptMethod -Name Send -Value {
        param ([string]$command)
        # Sends remote commands to the receiver; returns command and status acknowledged by receiver
        # Command is string of three letters attribute optionally followed by variable length value for attribute
        # When there is no value the current value of attribute is retrieved from the receiver
        # Example: MVLUP will increase the master volume by one unit
        # Example: MVL1E will set the volume to 1E (hexadecimal)
        #       All number parameters must be provided as hexadecimal string
        # Example: MVL will return the current master volume
        #       All numbers are returned as hex strings
        # Example: PWR00 will put the receiver in standby power mode
      
        if (!$this.Connected) { 'Not connected to a receiver'; return }
        if ($command.length -lt 3) { 'Command cannot be empty or less than 3 characters'; return }
        # If no parameter specified add QSTN to the command to query the value of the attribute
        if ($command.Length -eq 3) { $command += 'QSTN' }

        $cmd = [System.Text.Encoding]::ASCII.GetBytes($command.toUpper()) #Protocol requires all CAPS
        $cmdLength = [BitConverter]::GetBytes($cmd.Length + 4) # The +4 is for !1 at the begining and CR+LF at end of all commands
        [Array]::Reverse($cmdLength) # Make it Big-endian
        [byte[]]$packet = (73,83,67,80,0,0,0,16) + $cmdLength + (1,0,0,0,33,49) + $cmd + (13,10)
        $this.Stream.Write($packet, 0, $packet.Length)

        # Write any buffered data
        $this.Stream.Flush()

        Start-Sleep -Seconds 1

        # Now read the reply from the receiver
        # Many responses (notifications) may be queued up; read them all and return last reponse only
        while ($this.Stream.DataAvailable) {
            # Read the header and determine length of command

            [byte[]]$header = @()
            for ($i = 0; $i -lt 16; $i++) {
                try { $header += $this.Stream.ReadByte() } catch { 'Response timed out'; return }
            }
    
            # Get the command length. We need to reverse to little-endian before conversion to Int32
            $cmdLength = [BitConverter]::ToInt32($header[11..8], 0)
    
            # Now read the command
            [byte[]]$cmd = @()
            for ($i = 0; $i -lt $cmdLength; $i++) {
                try { $cmd += $this.Stream.ReadByte() } catch { 'Error reading response'; return }
            }

            # Strip first two and last two bytes, convert to ASCII and store
            $response = [System.Text.Encoding]::ASCII.GetString($cmd[2..($cmd.Length - 4)])
        }
        $response
    }

    $receiver
}

<# Sample usage
    $receiver = New-OnkyoReceiver
    for ($i=0; $i -lt 6; $i++) { if ($receiver.Discover()) { break } }
    if (!$receiver.connected) { throw 'Unable to discover and connect to receiver' }
    $receiver.Send('pwr01') #Power on
    $receiver.Send('mvl' + (20 | Convert-ToHex)) #Set master volume to 20
    $receiver.Send('sli24') #Select FM radio
    $receiver.Send('tun10670') #Tune to 106.7 (NYC area Lite FM)
    if ($receiver.Send('mvl') -match 'MVL(\d+)') { 'The current volume is ' + ($matches[1] | Convert-ToDec) }
    $receiver.Disconnect()
#>
