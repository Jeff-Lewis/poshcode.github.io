#The PowerShell Takl
#Demo 1 - Hypervisors
#ESX

#Connect to vCenter
Get-Credential | connect-viserver -Server "Your vCenter Address"

#Create Our Network
Get-VMHost "ESXServerName" | New-VirtualSwitch -Name "Test" -NumPorts 64

#And a Port Group on that network
Get-VMHost "ESXServerName" | get-virtualswitch -Name "Test" | New-VirtualPortGroup -Name "TestPG" -VLanId 10

#Change the available ports
Get-VMHost "ESXServerName" | Get-VirtualSwitch -Name "Test" | Set-VirtualSwitch -NumPorts 32

#Change our VLAN ID
Get-VMHost "ESXServerName" | Get-VirtualSwitch -Name "Test" | Get-VirtualPortGroup -Name "TestPG" | Set-VirtualPortGroup -VLanId 12

#Destroy it
Get-VMHost "ESXServerName" | Get-VirtualSwitch -Name "Test" | Get-VirtualPortGroup -Name "TestPG" | Remove-VirtualPortGroup -Confirm:$false
Get-VMHost "ESXServerName" | Get-VirtualSwitch -Name "Test" | Remove-VirtualSwitch -Confirm:$false
