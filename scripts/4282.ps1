#========================================================================
#Credits to http://poshcode.org/2886 as I leveraged some functions
#Please modify parameters in Email-RebootResult
#
#========================================================================

#========================================================================
#START: Initialization
param ($system)

cls
$Error.Clear()
$ErrorActionPreference = "Stop"

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO') | out-null

function Email-RebootResult
{
	param($subject)
	$emailrecipients = ""
	$emailfrom = ""
	$emailserver = ""

	Send-MailMessage -to $emailrecipients -from $emailfrom -smtpserver $emailserver -Subject $subject -attachment $log
}

function Write-RebootLog
{
	param($log, $msg, $errormsg)
	$now = (get-date).tostring('yyyy-MM-dd HH:mm:ss -')
	"$now $msg" | out-file -FilePath $log -Append
	Write-Host "$now $msg"
	if ($errormsg)
	{
		$errormsg | Out-File -FilePath $log -Append
		Write-Host $errormsg
	}
}
function Get-ClusterNode
{
    param($cluster)
    
    gwmi -class MSCluster_Node -namespace "root\mscluster" -computername $cluster -Authentication PacketPrivacy | add-member -pass NoteProperty Cluster $cluster

} #Get-ClusterNode

function Get-ClusterGroup
{
    param($cluster)

    gwmi -class MSCluster_ResourceGroup -namespace "root\mscluster" -computername $cluster -Authentication PacketPrivacy | add-member -pass NoteProperty Cluster $cluster  | 
    add-member -pass ScriptProperty Node `
    { gwmi -namespace "root\mscluster" -computerName $this.Cluster -Authentication PacketPrivacy -query "ASSOCIATORS OF {MSCluster_ResourceGroup.Name='$($this.Name)'} WHERE AssocClass = MSCluster_NodeToActiveGroup" | Select -ExpandProperty Name } |
    add-member -pass ScriptProperty PreferredNodes `
    { @(,(gwmi -namespace "root\mscluster" -computerName $this.Cluster -Authentication PacketPrivacy -query "ASSOCIATORS OF {MSCluster_ResourceGroup.Name='$($this.Name)'} WHERE AssocClass = MSCluster_ResourceGroupToPreferredNode" | Select -ExpandProperty Name)) }

} #Get-ClusterGroup

function Get-SQLInstance
{
    param($system, $isCluster)
    
	if ($isCluster)
	{
		$instances = (gwmi -class "MSCluster_Resource" -namespace "root\mscluster" -computername $system  -Authentication PacketPrivacy | where {$_.type -eq "SQL Server"} | Select @{n='Cluster';e={$cluster}}, Name, State, @{n='VirtualServerName';e={$_.PrivateProperties.VirtualServerName}}, @{n='InstanceName';e={$_.PrivateProperties.InstanceName}}, `
	    @{n='ServerInstance';e={("{0}\{1}" -f $_.PrivateProperties.VirtualServerName,$_.PrivateProperties.InstanceName).TrimEnd('\')}}, `
	    @{n='Node';e={$(gwmi -namespace "root\mscluster" -computerName $system -Authentication PacketPrivacy -query "ASSOCIATORS OF {MSCluster_Resource.Name='$($_.Name)'} WHERE AssocClass = MSCluster_NodeToActiveResource" | Select -ExpandProperty Name)}}).VirtualServerName
	}
	else
	{
		$instances = (Get-WmiObject win32_service -ComputerName $system | where {$_.displayname -like "SQL Server (*)" -and $_.startmode -eq "Auto"}).name
		$instances = $instances.replace("MSSQL$", "$system\")
		$instances = $instances.replace("MSSQLSERVER", "$system")
	}
    
	return $instances
} #Get-SQLInstance

function Verify-AllSQLInstances
{
	param($system, $isCluster, $log)
	
	try
	{
		Write-RebootLog $log "Getting all SQL instances"
		$instances = Get-SQLInstance $system $isCluster
		Write-RebootLog $log "$system has the following SQL instances:" $instances
	}
	catch
	{
		Write-RebootLog $log "Collecting SQL instance names failed with the following error: " $Error[0]
		throw "Collecting SQL instance names failed!"
	}

	foreach ($sql in $instances)
	{
		try
		{
			$sqlinstance = New-Object Microsoft.SqlServer.Management.Smo.server($sql)
			$sqlinstance.Refresh()
			Write-RebootLog $log "SQL instance $sqlinstance can be connected successfully"
			$db = $sqlinstance.Databases.Item("master")
			$ds = $db.ExecuteWithResults("select name, state_desc from sys.databases where state > 2")
			$t = $ds.Tables[0]
			if ($t.Rows.Count -ne 0)
			{
			   Foreach ($r in $t.Rows)
			   {
				  	Write-RebootLog $log "SQL Instance $sqlinstance has the following databases in problematic state"
					$name = $r.Item($t.Columns[0]) 
					$state = $r.Item($t.Columns[1])
					Write-RebootLog $log "Database $name is in $state state"
			   }
			   throw "database $name is in $state state"
			}
			else
			{
				Write-RebootLog $log "All databases on $sqlinstance are healthy"
			}
		}
		catch
		{
			Write-RebootLog $log "SQL instance $sqlinstance has the following error:" $error[0]
		}
	}
}#Verify-AllSQLInstances

$log = "C:\temp\Reboot-$system.log" #Create a cluster reboot log
if (Test-Path $log)
{
	remove-item $log -ErrorAction SilentlyContinue
}

try
{
	$PSComputerName  = (Get-WMIObject -Class Win32_OperatingSystem -ComputerName $system).PSComputerName
}
catch
{
	Write-RebootLog $log "Connecting WMI for $system failed with the following error: " $Error
	Email-RebootResult "Reboot-Alert: Get-WMIObject failed for $system, probably due to firewall issue"
	break;
}
$isCluster = ($system -ne $PSComputerName)

#END: Initialization
#========================================================================


#========================================================================
#START: Reboot each node of the given cluster

try
{
	if ($isCluster)
	{
		Write-RebootLog $log "Start rebooting the cluster $system"
		$servers = (get-clusternode -cluster $system | select name | sort name).name
		Write-RebootLog $log "The following nodes were found in the cluster $system" $servers
		Write-RebootLog $log "Rebooting each node in cluster $system one by one"
	}
	else
	{
		Write-RebootLog $log "Start rebooting the stand-alone server $system"
		$servers = $system
	}
	
	foreach($server in $servers)
	{
		Write-RebootLog $log "$server is rebooting"
		#Restart computer and wait until Wmi is up, Timeout after 15 mininutes
		restart-computer -computername $server -Wait -Timeout 900 -For Wmi -force -ErrorAction Stop
		Write-RebootLog $log "$server is back"
		
		#================================================================
		#START: Verify RDP
		$rdpTimeout = 150
		$rdpInterval = 30
		$rdpMaxCheckCount = $rdpTimeout/$rdpInterval
		$checkcount = 0
		while ($checkcount -le $rdpMaxCheckCount)
		{
			try
			{
				$checkcount++
				Write-RebootLog $log "Verifying $server can be connected over port 3389 (RDP)"
				$rdp = New-Object System.Net.Sockets.TCPClient -ArgumentList $server,3389
				Write-RebootLog $log "Verified $server can be connected over port 3389 (RDP)"
				break
			}
			catch
			{
				if ($checkcount -le $rdpMaxCheckCount)
				{
					Write-RebootLog $log "RDP Verification failed, try again after $rdpInterval seconds"
					start-sleep -seconds 30
					$Error.Remove($Error[0])
				}
				else
				{
					Write-RebootLog $log "$server cannnot be connected over port 3389 (RDP)"
					break
				}
			}
		}
		#END: Verify RDP
		#================================================================
	}
}

catch
{
	Write-RebootLog $log "The system $system was not rebooted successfully with the following error:" $error
	Write-RebootLog $log "Script terminated due to the above error!"
	Email-RebootResult "Reboot-Alert: The system $system was not rebooted successfully, script terminated"
	break
}

#END: Reboot each node of the given cluster
#========================================================================


#========================================================================
#START: For cluster, rebalance and verify each group is running on its preferred node.
#START: For both cluster and stand-alone server, verify all instances are healthy

try
{
	if ($isCluster)
	{
		#========================================================================
		#START: Rebalance groups so that every group runs on its preferred node

		try
		{
			Write-RebootLog $log "Rebalancing groups so that each group runs on its preferred node"
			$clustergroup = get-clustergroup -cluster $system

			foreach($group in $clustergroup)
			{
				try
				{
					#if the group is not running on its preferred node, move the group to its preferred node.
					$currentnode = $group.node
					if ($group.PreferredNodes.count -gt 0)
					{
						$preferrednode = $group.PreferredNodes[0]
					}
					$groupname = $group.Name
					if ($preferrednode -ne $null -and $currentnode -ne $preferrednode)
					{
						Write-RebootLog $log "Moving group $groupname from $currentnode to its preferred node $preferrednode"
						$group.MoveToNewNode($preferrednode, 120)
					}
					
					#bring the group online
					$group.BringOnline(120)
				}
				catch
				{
					Write-RebootLog $log "Moving group $groupname failed with the following error:" $error[0]
				}

			}
		}
		catch
		{
			Write-RebootLog $log "Rebalancing cluster groups failed with the following error:" $error[0]
		}
		
		#END: Rebalance groups so that every group runs on its preferred node
		#========================================================================


		#========================================================================
		#START: Verify that each group is running on its preferred node and each SQL instance can be connected
		try
		{
			$clustergroup = get-clustergroup -cluster $system
			
			foreach($group in $clustergroup)
			{
				try
				{
					$currentnode = $group.node
					if ($group.PreferredNodes.count -gt 0)
					{
						$preferrednode = $group.PreferredNodes[0]
					}
					$groupname = $group.Name
					$groupstate = $group.State
					#Notify DBA for each of the following situations:
						#a. the group is not online
						#b. the group is not running on its preferred node 
						#c. SQL cannot be connected

					#verify the group is online
					if ($groupstate -ne 0)
					{
						Write-RebootLog $log "Group $groupname cannot be brought online"
						throw "Group $groupname cannot be brought online"
					}
					else
					{
						Write-RebootLog $log "Group $groupname has been brought online"
					}
					
					#verify the group is running on its preferred node
					
					if ($preferrednode -ne $null)
					{
						if ($preferrednode -ne $currentnode)
						{
							Write-RebootLog $log "Group $groupname is not running on its preferred node"
							throw "Group $groupname is not running on its preferred node"
						}
						else
						{
							Write-RebootLog $log "Group $groupname is running on its preferred node $preferrednode"
						}
					}
				}
				catch
				{
					Write-RebootLog $log "Group $groupname encountered the following error:" $error[0]
				}
			}
		}
		catch
		{
			Write-RebootLog $log "Verifying cluster failed with the following error:" $error[0]
		}
		#END: Verify that each group is running on its preferred node and each SQL instance can be connected
		#========================================================================
	}
	
	Verify-AllSQLInstances $system $isCluster $log
}

finally
{
	if ($Error.Count -eq 0)
	{
		Write-RebootLog $log "The system $system was rebooted successfully"
		Email-RebootResult "Reboot-Confirmation: The system $system was rebooted successfully"
	}
	else
	{
		Write-RebootLog $log "The reboot of system $system encountered some issues"
		Email-RebootResult "Reboot-Alert: The reboot of system $system encountered some issues"
	}
}

#END: For cluster, rebalance and verify each group is running on its preferred node.
#END: For both cluster and stand-alone server, verify all instances are healthy
#========================================================================
