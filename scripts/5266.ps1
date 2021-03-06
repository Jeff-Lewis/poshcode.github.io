Function Get-LocalGroupMembers {
	# Function to query a remote machine's WMI namespace and retrieve the membership of requested local groups
	# Returns a hash table object with the group names as keys, and an array of members for that group as associated value
	#
	# SYNTAX:
	# 	Get-LocalGroupMembers -Computer <Target Computer Name> -Groups <Group/Array of groups to be queried>
	
	param(
		$computer,
		$groupnames
		)  
	
	# Create hashtable to specify exactly which properties we want Get-WMIObject below to return
	$prophash = @{
		Class = "Win32_GroupUser";
		Property = "GroupComponent","PartComponent";
		Computer = "$computer"
		}
	
	# Populate $groups with details of all local group members on target machine
	$groups = Get-WMIObject @prophash -ErrorAction Stop
	
	# Create blank $returnhash object to store results
	$returnhash = @{}
	
	# For each requested group...
	$groupnames | ForEach {
		# Populate $group with item for processing
		$group = $_
		# Populate $match with entries that match the current group name
		$match = $groups | Where {$_.GroupComponent –like "*$group*"}
		# For each matching entry in the list...
		$match = $match | ForEach {
			# Look at the "PartComponent" property, and match the Domain and Name values with a Regular Expression
			$_.partcomponent –match “.+Domain\=(.+)\,Name\=(.+)$” > $nul
			# Format these values into the standard Domain\Username format
			$matches[1].trim('"') + “\” + $matches[2].trim('"')  
			}
		# Add the formatted list of user accounts to the $returnhash, with the group name as the key
		$returnhash.Add($group,$match)
		}
	
	# Once all requested groups are processed, return the $returnhash object
	return $returnhash
}

Function Get-LocalUsers {
	# Function to retrieve an array of all local user accounts on a specified machine
	#
	# Syntax:
	# 	Get-LocalUsers -Computer <Target Computer Name>
		
	param (
		$computer
		)
	
	# Create hashtable to specify exactly which properties we want Get-WMIObject below to return
	$prophash = @{
		Class = "Win32_UserAccount";
		Property = "LocalAccount","Caption","Disabled";
		Computer = "$computer"
		}
	
	# Populate $accounts with a list of all accounts on the target machine
	$accounts = Get-WmiObject @prophash -ErrorAction Stop
	# Populate $local with just the accounts where property "LocalAccount" equals True.
	$local = $accounts | Where {$_.LocalAccount -eq $True}
	
	# Build a hash table of the groups and their Disabled status
	$return = @{}
	
	$enabled = $local | Where {$_.Disabled -eq $False}
	$enabled = $enabled.Caption
	$disabled = $local | Where {$_.Disabled -eq $True}
	$disabled = $disabled.Caption
	
	If ($enabled -ne $null) {
		$return.Add("Enabled",$enabled)
		}
	If ($disabled -ne $null) {
		$return.Add("Disabled",$disabled)
		}
	
	# Return the $return hash
	return $return
}

Function Get-Timestamp {
	# Quick function to generate a properly formatted time-stamp string
	$timestamp = Get-Date -DisplayHint DateTime
	$timestampstring = [string]$timestamp
	Return $timestampstring
	}

Function Get-LocalInfo {
	
	param(
		$system
		)

	# Try to perform the following code-block on the specified system. If there are problems, drop to "Catch" block below.
	Try {
		$progressstr = (Get-Timestamp) + " - Attempting to process system: " + $system
		$progressstr | Out-File $progresslog -Append
		# Populate $adminmembers with results returned by Get-LocalGroupMembers function (detailed above) for specified system's Administrators group
		$adminmembers = Get-LocalGroupMembers -computer $system -groupnames "Administrators"
		# Populate $localusers with results returned by Get-LocalGroupMembers function (detailed above) for specified system
		$localusers = Get-LocalUsers -computer $system
		
		# Create a hash table to store information about this specific computer
		$systemhash = @{
			# Save array of system's local administrator group members to property "Administrators"
			"Administrators" = $adminmembers.Get_Item("Administrators");
			# Save array of system's enabled local user accounts to property "LocalUsersEnabled"
			"LocalUsersEnabled" = $localusers.Get_Item("Enabled");
			# Save array of system's disabled local user accounts to property "LocalUsersDisabled"
			"LocalUsersDisabled" = $localusers.Get_Item("Disabled");
			# Use Get-Timestamp to record exactly when this information was exported, save as "ExportTime" property
			"ExportTime" = Get-Timestamp
			}
		
		# Add the information about the specified system to the $localhash with the system name as the key
		$global:localhash.Add($system,$systemhash)
		
		# Add confirmation to progress log
		$progressstr = (Get-Timestamp) + " - Completed processing for system: " + $system
		$progressstr | Out-File $progresslog -Append
		}
		
	# If there are any problems retrieving the group information...
	Catch [Exception] {
		# Build a log file entry with details of what went wrong
		$errorstring = "Unable to retrieve information about local groups/users for system " + $system + ". Error message: " + $_
		# And output it to the error log
		$errorstring | Out-File $errorlog -Append
		}
	}
	
#######################################
####   Environment Config Section  ####
#######################################

$basepath = "D:\Scratch\GroupCompare\"

$logfolder = $basepath + "Logs\"
#Create-Folder $logfolder

$reportfolder = $basepath + "Reports\"
#Create-Folder $reportfolder

$currentdate = Get-Date -Format "yyyy-MM-dd"
$outputfile = $reportfolder + $currentdate + "-Report.txt"
$changefile = $reportfolder + $currentdate + "-Changes.txt"
$errorlog = $logfolder + $currentdate + "-Error.log"
$progresslog = $logfolder + $currentdate + "-Progress.log"

$domainxml = $basepath + "DomainHashXML.xml"
$systemxml = $basepath + "SystemHashXML.xml"
$domainxmlarchive = $basepath + "DomainHashXML-Archive.xml"
$systemxmlarchive = $basepath + "SystemHashXML-Archive.xml"

# Read the list of domain groups and systems to query from text file, disregarding any empty lines
$domainfile = $basepath + "domaingroups.txt"
$sysfile = $basepath + "systems.txt"
$domaingroups = Get-Content $domainfile | Where {$_ -ne ""}
$systems = Get-Content $sysfile | Where {$_ -ne ""}

#######################################
#### Information Gathering Section ####
#######################################

# Create hash table to store information about domain and local groups
$localhash = @{}

#### The below works and populates $localhash with what I need ####
$stuff = "UKLDN00928","UKLDN051"
$stuff | ForEach {
	Get-LocalInfo -System $_
	}
	
#### But this doesn't ####
Invoke-Async -Set $systems -SetParam System -Cmdlet Get-LocalInfo
