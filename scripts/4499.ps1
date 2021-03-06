#========================================================================
# Created by:   Clint Jones
# Organization: Virtually-Genius
# Filename:     Fix-VMPortGroups
#========================================================================

#NOTES: For each run, you will be prompted to make selections for the $vcenter and $cluster variables
# 		$vSwitch names are pulled from a pre-populated table on line 30, based on cluster selection
# 		COMPARISON LISTS BEGINNING ON LINE 74 compares old groups to corresponding new group based on cluster selection (should match those in "portgroups.csv" and "oldgroups.txt")
#     	        Fill out "portgroups.csv" with the names and vLANs of all new portgroups that need to be created
# 		Fill out "oldgroups.txt" with the names of all the defunct portgroup names that need to be changed (these lists will be used later to delete empty portgroups)
# 		"vm_portgroup_log.txt" contains all information regarding VMs that failed ping tests after portgroup changes
# 		"vm_portgroup_previousconfig.txt" lists all VM's previous portgroup configs before changes are made for rollback 

#Select the correct cluster, vCenter server, and vSwitch
$vcenteranswer = Read-Host "What vCenter server do you want to connect to (Prod, Dev, or PCI)?"
switch ($vcenteranswer)
	{
	  Prod {$vcenter = "vCenter01.your.domain"}
	  Dev  {$vcenter = "vCenter02.your.domain"}
	  PCI  {$vcenter = "vCenter03.your.domain"}
	}
$cluster = Read-Host "What cluster do you want to connect to?" 		#(i.e. "Cluster1")
#Switch statement reflects which vSwitches are being modified for each cluster
#For this section enter each cluster name and list the vSw
$vSwitches = @()
switch ($cluster)
	{
	   Cluster1 {$vSwitches = "vSwitch1","vSwitch2"}
	   Cluster2 {$vSwitches = "vSwitch1","vSwitch2","vSwitch3"}
	   Cluster3 {$vSwitches = "vSwitch1"}
	}

#Call all snap-ins and connections
Import-Module ActiveDirectory
Add-PSSnapin VMware.VimAutomation.Core
Connect-VIServer -Server $vcenter -Credential (Get-Credential)

#Remove old log files and create new ones
New-Item -Path c:\scripts\logs\$cluster\vm_portgroup_log_failed_after.txt -Type File -Force
New-Item -Path c:\scripts\logs\vm_portgroup_previousconfig.txt -Type File -Force

foreach ($vSwitch in $vSwitches)
	{
	  # Create a list of all portgroups and associated vLANs
	  # This csv will have two fields ("Name" and "vLAN") and will contain all new portgroups that need to be created - create one for each vSwitch in each cluster (i.e. "C:\VMware_PortGroups\Cluster1\vSwitch1\portgroups(Cluster1 - vSwitch1).csv")
	  $portgroups = Import-Csv -Path "C:\VMware_PortGroups\$cluster\$vSwitch\portgroups($cluster - $vSwitch).csv"
	  foreach ($portgroup in $portgroups)
		  {
		    #Create new port groups on each of the ESX hosts
		   $hosts =  Get-Cluster $cluster | Get-VMHost
		    foreach ($line in $hosts)
		  	  {
			    $vswitchName = Get-VirtualSwitch -VMHost $line -Name $vSwitch
			    New-VirtualPortGroup -VirtualSwitch $vswitchName -Name $portgroup.Name -VLanId $portgroup.vLAN
			  }	
		  }
	}
#Change VMs over to the new port groups
#Create a txt file listing all old portgroups that need to be evacuated and replaced (i.e. "C:\VMware_PortGroups\Cluster1\oldgroups(Cluster1).txt")
$oldportgroups = @()
$oldportgroups = Get-Content "C:\VMware_PortGroups\$cluster\oldgroups($cluster).txt"
$allvms = Get-Cluster $cluster | Get-VM

foreach ($vm in $allvms)
	{
	  #By maintaining this variable as an array (regardless of the number of inputs) we can account for VMs with single or multiple existing portgroups	
	  $existinggroups = @()
	  $existinggroups += Get-VirtualPortGroup -VM $vm 
	  foreach ($existinggroup in $existinggroups)
		{
		  if ($oldportgroups -contains $existinggroup.Name)
		  	{
				    if ($cluster -eq "Cluster1")
						{
						 #Switch function to match old names to new corresponding groups (by cluster)
						 switch ($existinggroup.Name)
							{
						 	  	"OldGroup1" {$newgroup = "10.2.30.x 30"}
								"OldGroup2" {$newgroup = "10.4.19.x 19"}
								"OldGroup3" {$newgroup = "10.6.52.x 52"}
							}
						}
			         if ($cluster -eq "Cluster2")
						{
						 #Switch function to match old names to new corresponding groups
						 switch ($existinggroup.Name)
							{
						 	  	"OldGroup1" {$newgroup = "10.2.42.x 42"}
								"OldGroup2" {$newgroup = "10.4.81.x 81"}
								"OldGroup3" {$newgroup = "10.6.74.x 74"}
							}
						}
					 if ($cluster -eq "Cluster3")
						{
						 #Switch function to match old names to new corresponding groups
						 switch ($existinggroup.Name)
							{
						 	  	"OldGroup1" {$newgroup = "10.2.12.x 12"}
								"OldGroup2" {$newgroup = "10.4.31.x 31"}
								"OldGroup3" {$newgroup = "10.6.43.x 43"}
							}
						}
					
				#Change the port group based on the match made from the list above
				$networkadapter = Get-VM $vm | Get-NetworkAdapter | Where-Object{$_.NetworkName -eq $existinggroup.Name}
			 	Set-NetworkAdapter -NetworkAdapter $networkadapter -NetworkName $newgroup -Confirm:$false
			}
			    #Test connections
				Add-Content -Path c:\scripts\logs\vm_portgroup_previousconfig.txt "$vm is from the $existinggroup network."
				Start-Sleep -Seconds 5
				if ((Test-Connection $vm.Name -Count 2 -Quiet) -eq $false)
				{Add-Content -Path c:\scripts\logs\$cluster\vm_portgroup_log_failed_after.txt $vm}
		}
	}

#Check the differences between pre-script and post-script ping fail logs
New-Item -Path c:\scripts\logs\temp($cluster).txt -Type file
Get-Content -Path c:\scripts\logs\$cluster\failed_connections_prior_to_script.txt | Add-Content c:\scripts\logs\temp($cluster).txt
Get-Content -Path c:\scripts\logs\$luster\vm_portgroup_log_failed_after.txt | Add-Content c:\scripts\logs\temp($cluster).txt
Get-Content -Path c:\scripts\logs\temp.txt | Sort-Object | Get-Unique | Out-File c:\scripts\logs\$cluster\FAILED_VM_PINGS.txt
Remove-Item c:\scripts\logs\temp($cluster).txt -Force

