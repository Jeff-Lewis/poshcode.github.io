# Script to copy standard vSwitch config across all host within the cluster
# Modified by Leon Scheltema AVANCE ICT Groep Nederland

# Begin variables
$sourceVI = "New vCenter"
$BASEHost = "Base host"
# End variables

# Connect to vCenter server
Connect-VIServer "$sourceVI"

$NEWHost = Get-Cluster "Base host Cluster" | Get-VMhost

Foreach ($hosts in $NEWHost) {
Get-VMHost -Name $BASEHost |Get-VirtualSwitch |Foreach {
   If ((Get-VMHost -Name $hosts |Get-VirtualSwitch -Name $_.Name-ErrorAction SilentlyContinue)-eq $null){
       Write-Host "Creating Virtual Switch $($_.Name)"
       $NewSwitch = Get-VMHost -Name $hosts |New-VirtualSwitch -Name $_.Name-NumPorts $_.NumPorts-Mtu $_.Mtu
       $vSwitch = $_
                    }
                   $_ |Get-VirtualPortGroup |Foreach {
                       If ((Get-VMHost -Name $hosts |Get-VirtualPortGroup -Name $_.Name-ErrorAction SilentlyContinue)-eq $null){
                           Write-Host "Creating Portgroup $($_.Name)"
                           $NewPortGroup = Get-VMHost -Name $hosts |Get-VirtualSwitch -Name $vSwitch |New-VirtualPortGroup -Name $_.Name-VLanId $_.VLanID
                        }
                    }
}
}

# Disconnect from vCenter server
Disconnect-VIServer -server "$sourceVI" -Force -Confirm:$false
