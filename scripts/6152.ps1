# 22/12/2015 Anastasis Ksouzafeiris
# PowerCLI script: UpdateToolsPolicy.ps1
# You can run it like this eg.:
# powercli> Set-ExecutionPolicy -Unrestricted
# powercli> UpdateToolsPolicy.ps1 | Export-Csv "results.csv"
# This script is taking a file in .txt with the Hostnames or IPs
# and performs an update to the VM Tools Policy from manual to 
# "Upgrade VMware Tools on Power cycle".


$vCname = Read-host “Enter the vCenter or ESXi host name to connect”
Connect-viserver $vcname
$VirtualMachines = Get-Content "VMList.txt"
if (-not (Get-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue)) {
	Add-PSSnapin VMware.VimAutomation.Core
}
foreach ($vm in $VirtualMachines ) {
	if($_.config.Tools.ToolsUpgradePolicy -ne "UpgradeAtPowerCycle" {
		$config = New-Object VMware.Vim.VirtualMachineConfigSpec
		$config.ChangeVersion = $vm.ExtensionData.Config.ChangeVersion
		$config.Tools = New-Object VMware.Vim.ToolsConfigInfo
		$config.Tools.ToolsUpgradePolicy = "UpgradeAtPowerCycle"
		$vm.ExtensionData.ReconfigVM($config)
		Write-Host "Update Tools Policy on $vm completed"
	}
}
Disconect-VIServer -server $vCname -Force -Confirm:$false
