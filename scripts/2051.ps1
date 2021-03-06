
Param ($servercsv)

# $servercsv is the input file

<#
.SYNOPSIS
Mass cloning of virtual machines
.DESCRIPTION
Mass cloning of virtual machines from a template using a CSV file as a source.
.NOTES
 1- Assumes template only has a C: drive and that only a D: will be added from the CSV file.  Additional drives will have to be done manually.
 2- Input CSV file format is at the bottom of this file.
 3- When testing use this command to mass delete the VMs created with the script.
 	 import-csv inputfile.csv | % { Remove-VM -DeleteFromDisk -VM $_.Name -RunAsync -Confirm:$false }
 4- Folder is not set due to the likelihood of duplicate folder names in large environment.  There's no good, consistent, and easy way that I could figure out to handle that.
 5- Creating the additional disk fails with PowerCLI 4.0 U1.  Reference URLs on the next two lines:
 	http://blog.vmpros.nl/2009/08/21/vmware-number-of-virtual-devices-exceeds-the-maximum-for-a-given-controller/
	http://communities.vmware.com/thread/251601
 6- Setting the guest network fails with PowerCLI 4.0 U1.  I've posted the issue.
    http://communities.vmware.com/thread/262855
	** UPDATE- Issue with dvSwitches not supported in PowerCli yet.  Workaround here- http://www.lucd.info/2010/03/04/dvswitch-scripting-part-8-get-and-set-network-adapters/
	


Todos-
  1- Set the guest network config. with either Copy-VMGuestfile and Invoke-VMScript, or Set-VMGuestNetworkInterface.
  2- Clean up unnecessary output during script run.
  3- Create script to validate CSV file.  Possibly to be run by Project Managers.
  4- Create Excel spreadsheet with dropdown lists of cluster locations and other info to assist Project Managers.
.LINK
http://netops.ma.monster.com/virtech/VMware%20Wiki%20Library/Home.aspx
.EXAMPLE
C:\Temp> C:\ops\posh\VMware\Clone_Template_fromCSV.ps1 inputfile.csv
#>

<#
# ** Verify server names are unique **
$VMTargets = Import-CSV $servercsv
$VCs = "vcenter101.ma.tmpw.net","vcenter102.ma.tmpw.net","vcenter201.be.tmpw.net"
$VCs | % {
  Connect-VIServer $_ | Out-Null
  $AllVMs = Get-VM | Sort
  $i = 0;
  while ($VMTargets[$i]) {
    $j = 0
    while ($AllVMs[$j]) {
      If ($VMTargets[$i].Name -eq $AllVMs[$j].Name) {
        Write-Host "Requested VM name" $VMTargets[$i].Name "is in use. `n"
        $DupeNames = $true
      } # end If
    $j++
    } # end while
  $i++
  } # end while
} #end %



If ($dupenames = $false) {
#>

  $serverlist = Import-CSV $servercsv

  $serverlist | Format-Table -Autosize

  # ** Clone new VM
  $serverlist | % { 
    Connect-VIServer $_.VC #| Out-Null
	sleep 5
	New-VM -Confirm:$False `
           -Name ($_.Name).ToLower() `
           -Template $_.Template `
		   -DiskStorageFormat Thin `
           -ResourcePool (Get-ResourcePool -location $_.Cluster | Where { $_ -match $_.ResourcePool } | get-random) `
           -Description $_.Description `
           -VMHost (Get-VMHost -location $_.Cluster | Sort $_.CPuUsageMhz -Descending | Select -First 1) `
           -Datastore (C:\ops\posh\vmware\Get-DatastoreMostFree.ps1 $_.Cluster).Name
	Set-VM -Confirm:$false `
           -VM $_.Name `
           -NumCpu $_.NumCpu `
           -MemoryMB ([int]$_.RAMSizeGB * 1024)
	New-HardDisk -vm $_.Name -CapacityKB ([int]$_.D_DriveSizeGB * 1024 * 1024) -ThinProvisioned -Confirm:$false
	Get-NetworkAdapter -VM $_.Name | Set-NetworkAdapter -NetworkName $_.VLAN -Confirm:$false
	Set-CustomField -Entity $_.Name -Name "Clearquest #" -Value $_.CQTicket 
	Set-CustomField -Entity $_.Name -Name Environment -value $_.Environment
	Set-CustomField -Entity $_.Name -Name Owner -value $_.Owner
	Get-FloppyDrive -VM $_.Name | Remove-FloppyDrive -Confirm:$false
	Get-UsbDevice -VM $_.Name | Remove-UsbDevice -Confirm:$false
  } # end %
# } #end If

# Input file format
<#
VC,Cluster,Name,Description,Template,ResourcePool,NumCPU,RAMSizeGB,D_DriveSizeGB,VLAN,CQTicket,Environment,Owner
vcenterxxx.fqdn.com,Bed-QADevIntv35,QA-DBHYPESS201,Hyperion QA DB,w2k8_std_x64_r2_tmpl,Normal,1,3,50,VLAN350,DEV00451152,QA-Hyperion,Hyperion
#>

