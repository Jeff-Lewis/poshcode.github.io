Param (
	$viServer,
	$bakVM,
	$lxDest
)

#region check
if (!$viServer) { $viServer = Read-Host -Prompt "VI Server " }
if (!$bakVM) { $bakVM = Read-Host -Prompt "VM to Backup " }
if (!$lxDest) { $lxDest = Read-Host -Prompt "Backup Path (ex. /srv/backup) " }
#endregion

#region globalvars
$encoding = "OEM"
$version = "0.7"
$scriptout = @()
[regex]$curlpat = "(\s{1})+(.*vmdk$)"
#endregion

#region stkmvars
$viUser = "vmware"
$viPass = "vmware"
#endregion

Write-Host "viBackup Script Generator - " $version
Write-Host "--------------------------------------------"

if (($vmCon = Connect-VIServer -Protocol https $viServer) -eq "") { exit }
$vm = Get-VM $bakVM -Server $vmCon -ErrorAction SilentlyContinue

if (!$vm) {
	Write-Host "No VM found."
	Write-Host "Enter the Display Name from the VI Center:" -NoNewline
	$tvm = Read-Host
	if (!($vm=Get-VM $tvm -ErrorAction SilentlyContinue)) {
		return $false
		exit
	}
	Write-Host "You have entered 2 different Names. Please check that the VMX and the VM Name are the same!"
	Write-Host -ForegroundColor yellow "Entered VMX Name: {$bakVM}"
	Write-Host -ForegroundColor yellow "Entered VM Name: {$tvm}"
	Write-Host -ForegroundColor yellow "Returned VM Name: {$vm}"
	Write-Host -ForegroundColor yellow "IS THIS CORRECT (Yes/No)?:" -NoNewline
	$sure = Read-Host
	if ($sure -ne "yes") { exit }
}

#check Snapshots
if ((Get-Snapshot -VM $vm -Server $vmCon)) {
	Write-Host "VM has Snapshots. No Backup possible."
	return $false
	exit
}

#check HardDisk Mode
foreach ($hd in $vm.harddisks) {
	if ($hd.Persistence -ne "Persistent") {
		write-host "Hard Disk is not Persistent - no Snapshot allowed."
		return $false
		exit
	}
}

#write script
$scriptname = $vm.name + ".sh"
$vmname = $vm.name
$vmhost = $vm.Host
$vmview= Get-View $vm.id
$vmvname = $vmview.config.files.vmpathname

#generate Text

$header = "#!/bin/bash"
$user = "USER=`"${viUser}`""
$pass = "PASS=`"${viPass}`""
$dest = "DEST=`"${lxDest}`""
$lxVM = "VM=`"${vmname}`""
$dcPath = $vm | Get-Datacenter

#region writefile

$scriptout += $header 
$scriptout += $user 
$scriptout += $pass 
$scriptout += $dest 
$scriptout += $lxvm 
$scriptout += "" 
$scriptout += "BKUP=`"${vmvname}`"" 
$scriptout += "SNAPCHECK=``vmware-cmd -H ${viserver} -T ${vmhost} -U `${USER} -P `${PASS} `"`${BKUP}`" hassnapshot`` "
$scriptout += "if [ `"`$SNAPCHECK`" != `"hassnapshot () =`" ]; then `n echo 'VM has a Snapshot. Aborting...' `n exit `n fi" 
$scriptout += "vmrun -T esx -h https://${viserver}/sdk -u `${USER} -p `${PASS} snapshot `"`${BKUP}`" vmBackup"

# Hard Disk
foreach ($hd in $vm.Harddisks) {
	$hdname = $hd.Filename
	$patstr = $curlpat.split($hdname)
	#dirty hack
	$patstr[0] = $patstr[0].replace("[","")
	$patstr[0] = $patstr[0].replace("]","")	
	
	$dsPath = $patstr[0].replace(" ","%20")
	$vmdkpath = $patstr[2].replace(" ","%20")
	$vmdkflatpath = $patstr[2].replace(".vmdk","-flat.vmdk")
	
	#curl options
	$vmdk = "curl --user `${USER}:`${PASS} -o `${DEST}/`${VM}.vmdk `"https://${viserver}/folder/${vmdkpath}?dcPath=${dcPath}&dsName=${dsPath}`" --insecure "
	$vmdkflat = "curl --user `${USER}:`${PASS} -o `${DEST}/`${VM}.vmdk `"https://${viserver}/folder/${vmdkflatpath}?dcPath=${dcPath}&dsName=${dsPath}`" --insecure"

	#$vmdk = "vifs --server ${viserver} --dc 'KM' --username `${USER} --password `${PASS}  --get `"``echo $hdname```" `${DEST}/`${VM}.vmdk "
	#$vmdkflat = "vifs --server ${viserver} --dc 'KM' --username `${USER} --password `${PASS}  --get `"``echo $hdname | sed 's/.vmdk/-flat.vmdk/g'```" `${DEST}/`${VM}-flat.vmdk "

	$scriptout += $vmdk
	$scriptout += $vmdkflat
}

$scriptout += "vmrun -T esx -h https://${viserver}/sdk -u `${USER} -p `${PASS} deleteSnapshot `"`${BKUP}`" vmBackup" 

$scriptout | Out-File $scriptname -Encoding $encoding
#endregion

Write-Host "Finished"
Write-Host "Don't forget to convert the script under *nix/Linux with dos2unix!"

