# vminfo.ps1
#
# Give this a VMware guest and it will attempt to dump all the information available.
#
# Example: .\vminfo.ps1  "guestname"
#
# This scripts assumes that you have already connected to a VirtualCenter server.
#
# This was developed and tested using VMware vSphere PowerCLI version 4.1.1.2816
# on an ESXi 4.1 build 381591 cluster

Param($guest)

####################################################################
# ProcessObject - This recursive function does the bulk of the work. 
#
#Input Parameters
#
# $xobj - Object to dump info on
# $pref - Prefix to use on print lines
# 
# When an object is encountered then we recursively call ourselves  to
# process that object after first updating the prefix.
#
# Snapshot objects can point to both a parent and a child. Dumping both
# Parent and Child objects results in an endless loop. Therefore dump only
# Child objects.

function ProcessObject ($xobj, $pref){
    $plen = $pref.length
	$pad = $width - $plen
	If ($pad -lt 0){$pad = 0}
	# Get information on all of the members of this object because what is done with a member is
	# dependent on whether the member is an object or is a data item and if it is a data item
	# what kind of data item is it
	$xom = $xobj | get-member -membertype property
    foreach ($ent in $xom){
		$xnam = $ent.name
		#write-host ">>>>>>>Processing entry" $ent.name
        $xnlen = $xnam.length
        $strs = $ent.Definition.split(" ")
		
		# process 1st level simple things like strings and numbers including simple arrays
		
		# There are some fields in a VMware guest "Get-View" description we will ignore
		# because they are obsolete and have either had their descriptive names changed
		# or a new cmdlet is now available and it is the preferred method for finding
		# out about the object.
		# 
		# The following "objects" may be encountered but will be ignored. These are legacy objects 
		# from ESX 3.5 but were promoted to having their own cmdlets in ESX 4. Therefore we will
		# ignore them when found as members of some other object prefering to examine them using the
		# new cmdlets.
		#
		# legacy guest objects
		#
		# CDDrives == Get-CDDrives
		# FloppyDrives == Get-FloppyDrive
		# HardDisk == Get-HardDisk
		# NetworkAdapters == Get-NetworkAdapter
		# UsbDevices == Get-UsbDevice
		#
		# legacy host objects
		#
		# ConsoleNic == Get-VMHostNetworkAdapter
		# PhysicalNic == Get-VMHostNetworkAdapter
		# VirtualNic == Get-VMHostNetworkAdapter
		# VirtualSwitch == Get-VirtualSwitch
		# ScsiLun == Get-ScsiLun
		#
		#
		
        if ($xnam -match "^(CDDrives|FloppyDrives|HardDisks|NetworkAdapters|UsbDevices)$" ){
			"{0,-$plen}{1,-1}{2,-$pad}{3,-2}{4,-30}" -f $pref, ".", $xnam, ":", "== skipping legacy device object ==" #| Out-File -FilePath $reportfile -Append
		}
		elseif ($xnam -match "^(ConsoleNic|PhysicalNic|ScsiLun|VirtualNic|VirtualSwitch)$" ){
			#Write-Host "****** skipping legacy Network Adapter object- $xnam"
			"{0,-$plen}{1,-1}{2,-$pad}{3,-2}{4,-30}" -f $pref, ".", $xnam, ":", "== skipping legacy Network Adapter object ==" #| Out-File -FilePath $reportfile -Append
		}
		# The following are obsolete identifiers in ESX 3.5 that have new names as of ESX version 4.x
		# We will ignore all old identifiers and only display the new identifiers.
		#
		# Description - replaced by Notes
		# Host is replaced by VMHost
		# HostId is replaced by VMHostId
		# State == ConnectionState
		# VirtualMachineId == VMId
		elseif ($xnam -match "^(Description|Host|HostId|State|VirtualMachineId)$" ){
			"{0,-$plen}{1,-1}{2,-$pad}{3,-2}{4,-30}" -f $pref, ".", $xnam, ":", "== skipping obsolete identifier ==" #| Out-File -FilePath $reportfile -Append
		}
		# Examining the following will result in recursive loops threrfore we will skip them.
		#
		# Parent
		# VM
		# VMHost
		elseif ($xnam -match "^(VMHost)$" ){
			"{0,-$plen}{1,-1}{2,-$pad}{3,-2}{4,-30}" -f $pref, ".", $xnam, ":", "== skipping object to avoid infinite loop ==" #| Out-File -FilePath $reportfile -Append
		}
		elseif ($strs[0] -match "^System.String\[\]" ){
			if (!$xobj.$xnam.count) {
				$res = $xobj.$xnam
				#Write-Host "===  single entry array name ="  $xnam "result" $res
				"{0,-$plen}{1,-1}{2,-$pad}{3,-2}{4,-30}" -f $pref, ".", $xnam, ":", $xobj.$xnam #| Out-File -FilePath $reportfile -Append
			}
			else {
				$count = $xobj.$xnam.count
				for ($i=0; $i -lt $count; $i++){
					$namlen = $xnam.length
					$ipad = $pad - 2 - $namlen
					If ($i -gt 9){$ipad--}
					If ($ipad -lt 1){$ipad = 1}
					"{0,-$plen}{1,-1}{2,-$namlen}{3,1}{4,1}{5,-$ipad}{6,-2}{7,-30}" -f $pref, ".", $xnam, "[", $i, "]", ":", $xobj.$xnam[$i] #| Out-File -FilePath $reportfile -Append
				}
			}
		}
		elseif ($strs[0] -match "^System.(String|Int|Nullable|Boolean|DateTime|Double)" ){
			# If this is a "value__" then show the number and the symbolic name
			if ($xnam -eq "value__"){
				$vpad = $pad + 3
				"{0,-$plen}{1,$vpad}{2,-2}{3,-2}{4,-30}" -f $pref, ": ", $xobj.$xnam, "-", $xobj #| Out-File -FilePath $reportfile -Append
			}
			else {
				"{0,-$plen}{1,-1}{2,-$pad}{3,-2}{4,-30}" -f $pref, ".", $xnam, ":", $xobj.$xnam #| Out-File -FilePath $reportfile -Append		
			}
		}
        elseif ($strs[0] -match "^VMware.Vim(.|Automation.Types|Automation.ViCore)"){
			# Hack to avoid closed loop when crawling snapshot structures
			# Each child points back to its parent and each parent points to its children
			# hence and endless loop. Therefore do not process parents
			if ($xnam -match "^(Parent|ParentSnapshot|VM)$"){
				$pad = $width-$plen
				If ($pad -lt 0){$pad = 0}
				"{0,-$plen}{1,-1}{2,-$pad}{3,-2}" -f $pref, ".", $xnam, ": == skipping $xnam to avoid infinite loop ==" #| Out-File -FilePath $reportfile -Append
			}
			else {
	            $pad = $width-$plen
				If ($pad -lt 0){$pad = 0}
	            $yobj = $xobj.$xnam
				$newp = $pref + "." + $xnam
				if (!$yobj){
					"{0,-$plen}{1,-1}{2,-$pad}{3,-2}" -f $pref, ".", $xnam, ": =undefined=" #| Out-File -FilePath $reportfile -Append
				}
				else{
					if (!$yobj.count){
						ProcessObject $yobj $newp
					}
					else {
						$lc = $yobj.count
						for ($z = 0; $z -lt $lc; $z++){
							$zobj = $yobj[$z]
							$zperf = $newp + "[" + $z + "]"
							ProcessObject $zobj $zperf
						}
					}
				}
			}
		}
		elseif ($strs[0] -match "^System.(Collections)" ){
			Foreach ($entry in $xobj.$xnam){
				$newpref = $pref + "." + $xnam
				$cpad = $pad - $xnam.length - 1
				If ($cpad -lt 0){$cpad = 0}
				"{0,-$plen}{1,-1}{2,-$Cpad}{3,-2}{4,-30}" -f $newpref, ".", $entry.Key, ":", $entry.value #$strs[0] #| Out-File -FilePath $reportfile -Append
			}
		}
		else {
            "{0,-$plen}{1,-1}{2,-$pad}{3,-2}{4,-30}" -f $pref, ".", $xnam, ":", $ent.Definition #$strs[0] #| Out-File -FilePath $reportfile -Append
		}
	}	
}

function POLauncher ($xobj, $pref){
	if (!$xobj.count){
		ProcessObject $xobj $pref
	}
	else {
		$lc = $xobj.count
		for ($z = 0; $z -lt $lc; $z++){
			$zobj = $xobj[$z]
			$zperf = $pref + "[" + $z + "]"
			ProcessObject $zobj $zperf
		}
	}
}

# end function ProcessObject


$reportfile = "vminfo-rpt.txt"
$first = 20
$width = 70

$xvm = get-vm -name $guest
$prefix = $xvm.name + " Get-VM"
POLauncher $xvm $prefix


# Display information about virtual devices attached to the guest
# Process devices CDDrives|Harddisk|FloppyDrives|NetworkAdapters|UsbDevices

$dvm = get-HardDisk -vm $xvm
$prefix = $xvm.name + " Get-HardDisk"
POLauncher $dvm $prefix

$cdvm = get-CDDrive -vm $xvm
$prefix = $xvm.name + " Get-CDDrive"
POLauncher $cdvm $prefix

$flpvm = get-FloppyDrive -vm $xvm
$prefix = $xvm.name + " Get-FloppyDrive"
POLauncher $flpvm $prefix

$netvm = get-NetworkAdapter -vm $xvm
$prefix = $xvm.name + " Get-NetworkAdapter"
POLauncher $netvm $prefix

$usbvm = get-UsbDevice -vm $xvm
$prefix = $xvm.name + " Get-UsbDevice"
POLauncher usbvm $prefix

#Get-View return more information than Get-Vm
$xview = $xvm | get-view
$prefix = $xvm.name + " Get-View"
POLauncher $xview $prefix

# Return information about any snapshots.
$snap = get-snapshot $xvm
if ($snap){
	$prefix = $xvm.name + " Get-Snapshot"
	POLauncher $snap $prefix
}

#Tell ua about the host we are running on
$vmhost = $xvm.VMHost
$prefix = $vmhost.name + " Get-VMHost"
POLauncher $vmhost $prefix

# probably don't want to do this one unless you want to be buried in data
#$vmhostv = Get-View $vmhost
#$prefix = $vmhostv.name + " Get-View"
#POLauncher $vmhostv $prefix

#Dump information about the Host's devices 

$nics = Get-VMHostNetworkAdapter $vmhost
foreach ($nic in $nics){
	$prefix = $vmhost.name + " " + $nic.Name
	POLauncher $nic $prefix
}



$vmguest = get-vmguest $xvm
$prefix = $xvm.name + " Get-VMGuest"
#POLauncher $vmguest $prefix


$vmdatastore = get-datastore -vm $xvm
$prefix = $xvm.name + " Get-Datastore"
POLauncher $vmdatastore $prefix

$dc = Get-Datacenter -vm $xvm
$prefix = $xvm.name + " Get-Datacenter"
#POLauncher $dc $prefix

    
