#=============================================================================
#
#	PST Utilities - For Discovery, Import, Removal
#
#	Dan Thompson
#	dethompson71 at live dot com
# 
# This collection of tools for importing PSTs has been pieced together
# over many months of trial and error.
#
# Goal is to get PST files off the user's home share and into an archive mailbox.
#
# Throughout these scripts, what Microsoft calls a "Personal Archive" and 
# "Archive Mailbox," we call an "Online PST" or "Online Archive PST." 
# All these terms are the same thing.
# 
# We used the name "Online PST" due to the user's fear of the word "Archive"
#
# They thought we were pushing their mail down some hole and they would
# never see it again. "Online PST" is more friendly and helps them understand 
# the overall goal. Once we started importing PSTs for users, others saw the
# increased quota, as well as seeing the mail in OWA, and many requests 
# started pouring in. 
#
# All part of our evil plan to erradicate PST files. ;)
#
# The reason we created these scripts and made particular choices are detailed here: 
# http://powershellatwork.blogspot.com/2012/01/enterprise-wide-pst-import-beginnings.html
#
# Yes, we know about the tool PST Capture, but it just wasn't going to work for us.
# 
# requires Quest Powershell Commands for Active Directory
# (Active Roles Management Shell)
# http://www.quest.com/powershell/activeroles-server.aspx
#
#	I don't claim any of this to be perfect or work for every person out of the
#	box. You will certainly have to modify some settings to begin using this set
#	of tools in your environment. 
#	
#	I hope someone can use this as a starting point if they are in a 
#	similar situation. 
#
#	I also suggest you at least try PST Capture first. It did not work for me for
#	varous reasons. Your mileage may vary.
#
#
#=============================================================================



#=============================================================================
#	File Locations: PSTImportJobQueue; ReportJobQueue; PSTFileLogQueue
#=============================================================================

#====> TO DO -- add your servername and drive location
$Script:PSTServer			= '<ServerBIOSName>'	# example 'Ex01'
$Script:PSTDrive			= '<drive>'				# admin share example: 'd$'

$Script:PSTShareDir			= '\\' + $Script:PSTServer + '\PSTImports'	#Exchange servers must have rights to this share
$Script:PSTUNCDir			= '\\' + $Script:PSTServer + '\' + $Script:PSTDrive + '\Web\Data\pstimports'	#UNC path to same share
$Script:CASConnectLogDir	= '\\' + $Script:PSTServer + '\' + $Script:PSTDrive + '\Web\Data\CASConnectLogs' # where 'Connect' logs are kept
$Script:ReportsUNCDir		= '\\' + $Script:PSTServer + '\' + $Script:PSTDrive + '\Web\Data\Current'	#UNC path to report results

$Script:PSTQueueFile		= $Script:PSTShareDir + '\PSTImportJobQueue.csv'
$Script:PSTCompeletDir     	= $Script:PSTShareDir + '\^Completed'	# so it always shows at the top
$Script:PSTCompleteFile		= $Script:PSTShareDir + '\PSTImportCompleteQueue.csv' # Completed PST Import Jobs
$Script:NotifiedFile  		= $Script:PSTShareDir + '\PSTImportJobNotified.txt' # Users who have been notified
$Script:ArchReportFile     	= $Script:PSTUNCDir   + '\ArchiveReport.csv'	# The daily archive report (also a webpage)
$Script:ArchPSTFile        	= $Script:PSTUNCDir   + '\ArchivePSTHistory.csv' # history of PSTs owned by Archive Mailbox users
$Script:MoveFileLog 		= $Script:PSTUNCDir   + '\MovePSTFIles-' + $Script:T + '.log' # the Move log created when run
$Script:AllPSTFileLog		= $Script:PSTUNCDir   + '\AllPSTHistory.csv' # the history of ALL PST files discovered

# always shows at the bottom of directory listings
$Script:ImportQueueFileBU  	= $Script:PSTShareDir + '\ZZSavedQueueLogs\PSTImportJobQueue' + "-" + $Script:TE + ".csv" # backup of ImportQueue
$Script:CompleteQueueFileBU	= $Script:PSTShareDir + '\ZZSavedQueueLogs\PSTImportCompleteQueue' + "-" + $Script:TE + ".csv" #backup of Completed Jobs
$Script:ArchReportFileBU   	= $Script:PSTUNCDir   + '\ZZSavedQueueLogs\ArchiveReport-' + $Script:TE + '.csv' #back up of a report that is generated daily?	
$Script:ArchPSTFileBU     	= $Script:PSTUNCDir   + '\ZZSavedQueueLogs\ArchivePSTHistory-' + $Script:TE + '.csv' # back up of ArchiveMailboxOwners PSTs
$Script:AllPSTFileLogBU		= $Script:PSTUNCDir   + '\ZZSavedQueueLogs\AllPSTHistory-' + $Script:TE + '.csv' # backup of history of ALL psts discovered

#=============================================================================
#	Variables
#=============================================================================

# This site name is used to determine what tool is used to copy files.
# Copy-item is used for local PST files; BITS is used for distant files.
$Script:LocalADSite         = 'HQ' 

$Script:PSTUtilityVersion 	= "14.1.20121015"
$Script:MinRunJobs     		= 9  # minimum jobs running before we start more - 0 means no jobs can be running
$Script:MaxRunJobs     		= 19 # how many job can run at once
$Script:FreeSpaceLimit		= 199471 # set in MB, the lowest you want free space to go on the Import Share
$Script:T           		= Get-Date -Format yyyyMMdd # today
$Script:TE           		= Get-Date -Format yyyyMMddhhmmss # today extended

$Script:SMTPServer			= "smtpserver.domain.com"					# where to send
$Script:AdminEmail			= "admin1@domain.com, admin2@domain.com"	# gets notified, sent daily summary report email
$Script:BossEmail			= "boss@domain.com"							# send daily report on Wednesday only (Weekly Summary Report)
$Script:FromEmail			= "EmailTeam@domain.com"					# from address of reports to porcessed users
$Script:FromReportEmail		= "PSTReports@domain.com"					# from Address of manager's summary reports

#=============================================================================
# these are all the people that have applications which generate and process .PST files 
# but are Java configuration files. Not Mail. Ignore anything not in an "Outlook" directory
# --> Add DisplayName of user...
$Script:SpecialPeople = @("<DisplayName1>","<Displayname2>")

#=============================================================================
# These users will be ignored and not 'messed with'
# There will be some ;)
$Script:IgnoreUsers   = @("<DisplayName1>","<DisplayName2>") 


#=============================================================================
#	Job Objects: PSTJob; ReportJob; PSTFileLog
#=============================================================================

Function New-PSTFileLogObject(){
<#
.SYNOPSIS
	Return a new object to track a PST file.

.DESCRIPTION
	Return a new object to track a PST file.
	This is created for each new PST discovered for any user
	
#>
	$PSTObj = New-Object PSObject
	$PSTObj | Add-Member -type NoteProperty -name UNCFullPathName			-value (0)
	$PSTObj | Add-Member -type NoteProperty -name LastWriteTime				-value ("")
	$PSTObj | Add-Member -type NoteProperty -name Size						-value (0)
	$PSTObj | Add-Member -type NoteProperty -name IgnoreFile				-value ("FALSE")
	$PSTObj | Add-Member -type NoteProperty -name DateRemoved				-value ("")
	$PSTObj | Add-Member -type NoteProperty -name BackupFolksNotified		-value ("FALSE")
	$PSTObj | Add-Member -type NoteProperty -name AgeInDays					-value (0)
	
	$PSTObj
}
Function Get-ArchPSTIndex ($PST=$null) {
<#
.SYNOPSIS
	Creates or finds an index number for PST name.
	
.DESCRIPTION
	Creates or finds an index number for PST name.
	Uses the full UNC path for index building

#>
	
	$Return = $null`
	
	If ($Script:PSTIndex.ContainsKey($PST.VersionInfo.FileName)) {
		# return the Index number
		$Return = $PSTIndex.Item($PST.VersionInfo.FileName)
	} Else {
		# not found so this is a never before see file
		
		# create the entry for the file
		$PSTLog = New-ArchPSTFileLogObject
		$PSTLog.UNCFullPathName = $PST.VersionInfo.FileName
		$Script:ArchPSTQueue += $PSTLog
		# create the index and add it to 
		$Script:PSTIndex.Add($PSTLog.UNCFullPathName,$Script:ArchPSTQueue.Count)
		$Return = $Script:ArchPSTQueue.Count
	}
	
	$Return
	
}
Function New-ArchPSTFileLogObject(){
<#
.SYNOPSIS
	Return a new object to track PST file.

.DESCRIPTION
	Return a new object to track a PST file.
	This is created for each new PST discovered for any users with an Archive Mailbox
	
#>
	$PSTObj = New-Object PSObject
	$PSTObj | Add-Member -type NoteProperty -name UNCFullPathName			-value (0)
	$PSTObj | Add-Member -type NoteProperty -name LastWriteTime				-value ("")
	$PSTObj | Add-Member -type NoteProperty -name Size						-value (0)
	$PSTObj | Add-Member -type NoteProperty -name IgnoreFile				-value ("FALSE")
	$PSTObj | Add-Member -type NoteProperty -name DateChecked				-value ("")
	$PSTObj | Add-Member -type NoteProperty -name BackupFolksNotified		-value ("FALSE")
	$PSTObj | Add-Member -type NoteProperty -name AgeInDays					-value (0)
	$PSTObj | Add-Member -type NoteProperty -name AcctName					-value ("")
	$PSTObj | Add-Member -type NoteProperty -name Dept						-value ("")
	$PSTObj | Add-Member -type NoteProperty -name Server					-value ("")
	$PSTObj | Add-Member -type NoteProperty -name DateDiscovered			-value (Get-date)
	$PSTObj | Add-Member -type NoteProperty -name DateCreated				-value ("")
		
	$PSTObj

}
Function Get-PSTFileIndex ($PST=$null) {
<#
.SYNOPSIS
	Creates or finds an index number for PST name.
	
.DESCRIPTION
	Creates or finds an index number for PST name.
	Uses the full UNC path for index building

#>
	
	$Return = $null`
	
	Write-Host "Enter [Get-PSTFileIndex]: $(($PST).VersionInfo.FileName) Count: $(($Script:AllPSTQueue).Count)"
	
	If ($Script:PSTIndex.ContainsKey($PST.VersionInfo.FileName)) {
		# return the Index number
		$Return = $Script:PSTIndex.Item($PST.VersionInfo.FileName)
		Write-Host "Found [Get-PSTFileIndex]: $($Return)"
	} Else {
		# not found so this is a never before seen file
		
		# create the entry for the file
		$PSTLog = New-PSTFileLogObject
		$PSTLog.UNCFullPathName = $PST.VersionInfo.FileName
		Write-Host "Fullname $(($PSTLog).UNCFullPathName)"
		
		Write-Host "Before: " $PSTLog
 		
		$Script:AllPSTQueue += $PSTLog
		Write-host "After: " $Script:AllPSTQueue[-1]
		
		# create the index and add it to 
		#$Script:PSTIndex.Add($_.UNCFullPathName,$i)
		$Script:PSTIndex.Add($PSTLog.UNCFullPathName,($Script:AllPSTQueue).Count-1)
		Write-Host "Added? : " $Script:PSTIndex.Get_item($PSTLog.UNCFullPathName)
		$Return = ($Script:AllPSTQueue).Count -1
		
		Write-host "Try to reindex in: " $Script:AllPSTQueue[($Return)]
		Write-Host "Add [Get-PSTFileIndex]: $($Return)"
		
	}
	Write-Host "Leave [Get-PSTFileIndex]"
	$Return
	
	
}
Function New-PSTJobObject() {
<#
.SYNOPSIS
	Object for storing information about a PST Import Job.

.DESCRIPTION
	Object for storing information about a PST Import Job.
	A user many have many Jobs, one for each PST file being imported.
#>

	$PSTJob = New-Object PSObject
	
	# User Related 
	$PSTJob | Add-Member -type NoteProperty -name JobName      	-value ("")	# <userobj>-<filename>
	$PSTJob | Add-Member -type NoteProperty -name JobStatus    	-value ("")	# <>
	$PSTJob | Add-Member -type NoteProperty -name UserMBX		-value ("")	# DisplayName
	$PSTJob | Add-Member -type NoteProperty -name UserEmail		-value ("")	# PrimarySMTPAddress
	$PSTJob | Add-Member -type NoteProperty -name UserObj		-value ("")	# NTAccopuntName
	$PSTJob | Add-Member -type NoteProperty -name HomeDir		-value ("")	# from QADuser
	$PSTJob | Add-Member -type NoteProperty -name ClientVer		-value ("")	# from CAS logs if found
	$PSTJob | Add-Member -type NoteProperty -name ClientVerOK	-value ("")	# True/False
	
	# User PC Related
	$PSTJob | Add-Member -type NoteProperty -name IP			-value ("") # ComputerName, IP, or None (order of preference)
	$PSTJob | Add-Member -type NoteProperty -name OSname		-value ("") # X, 7, or none
	
	# PST File Related
	$PSTJob | Add-Member -type NoteProperty -name ProcessFile	-value ($True) # for potentially turning off one PST in a group
	$PSTJob | Add-Member -type NoteProperty -name OrgFileName	-value ("") # should be file name only
	$PSTJob | Add-Member -type NoteProperty -name OrgUNCName	-value ("") # UNC file name Original location
	$PSTJob | Add-Member -type NoteProperty -name TargetDir		-value ("") # target directory for creation
	$PSTJob | Add-Member -type NoteProperty -name TargetUNCName	-value ("") # UNC file name Target location
	$PSTJob | Add-Member -type NoteProperty -name FileSize  	-value (0) # file size in MB
	$PSTJob | Add-Member -type NoteProperty -name FileLastWrite	-value ("") # last write time of file
	
	# Migration Related
	$PSTJob | Add-Member -type NoteProperty -name TargetDB		-value ("")	# target archive mailbox location
	$PSTJob | Add-Member -type NoteProperty -name MRServer		-value ("")	# which MRS server to use - depends on AD site
	$PSTJob | Add-Member -type NoteProperty -name LastNumBI		-value (0) 	# from results, how many bad items did we encounter?
	$PSTJob | Add-Member -type NoteProperty -name UseTargetRootFolder	-value ($true) # True/False
	$PSTJob | Add-Member -type NoteProperty -name TargetRootFolder	-value ("") # True/False
	$PSTJob | Add-Member -type NoteProperty -name JobCreationTime	-value ($null)	
	
	# Update Related
	$PSTJob | Add-Member -type NoteProperty -name LastCheckTime	-value ($null)	# last time this entry processed
	$PSTJob | Add-Member -type NoteProperty -name InProgressTime -value ($null)	# from results
	$PSTJob | Add-Member -type NoteProperty -name OverAllTime	-value ($null)	# from results
	$PSTJob | Add-Member -type NoteProperty -name ExpandedErrs	-value ($null)	# any encountered errors
	$PSTJob | Add-Member -type NoteProperty -name RegPSTGrow	-value ($false)	# has been added to group for GPO to PSTDisableGrow?- my signal this user is complete - check membership
	$PSTJob | Add-Member -type NoteProperty -name SkipReason	-value ("")		# when a file is skipped, Size, Age, or Failed
	
	$PSTJob
}
Function New-PSTReportObj (){
<#
.SYNOPSIS
	PST Report Object for tracking the progress of PST migration.

.DESCRIPTION
	PST Report Object for tracking the progress of users with 
	an Archive Mailbox and their progress at removing PST files 
	from their home drives.
	

#>

	$ReportObj = New-Object PSObject
	
	# OverallUser Info
	$ReportObj | Add-Member -type NoteProperty -name DisplayName		-value ("")
	
	# PST Information
	$ReportObj | Add-Member -type NoteProperty -name InUsePST			-value (0)
	$ReportObj | Add-Member -type NoteProperty -name HDrvPST			-value (0)
	$ReportObj | Add-Member -type NoteProperty -name HDrvSize			-value (0)
	$ReportObj | Add-Member -type NoteProperty -name ImpPST				-value (0)
	$ReportObj | Add-Member -type NoteProperty -name ImpSize			-value (0)
	$ReportObj | Add-Member -type NoteProperty -name TotalSize			-value (0)
	$ReportObj | Add-Member -type NoteProperty -name SkippedPST			-value (0)
	$ReportObj | Add-Member -type NoteProperty -name DaysSinceImport	-value (0)
	$ReportObj | Add-Member -type NoteProperty -name GPO				-value ("")
	$ReportObj | Add-Member -type NoteProperty -name '-'				-value ("")
	
	# General MBX INfo
	$ReportObj | Add-Member -type NoteProperty -name MBXDB				-value ("")
	$ReportObj | Add-Member -type NoteProperty -name ArchDB				-value ("")
	$ReportObj | Add-Member -type NoteProperty -name MBXSize			-value (0)
	$ReportObj | Add-Member -type NoteProperty -name MBXQuota			-value (0)
	$ReportObj | Add-Member -type NoteProperty -name ArchSize			-value (0)
	$ReportObj | Add-Member -type NoteProperty -name ArchQuota			-value (0)
	$ReportObj | Add-Member -type NoteProperty -name InitArchSize		-value (0)
	$ReportObj | Add-Member -type NoteProperty -name ArchGrowth			-value (0)
	$ReportObj | Add-Member -type NoteProperty -name DateCreated		-value ((Get-Date))
	
	
		
	$ReportObj
}
Function Reset-PSTBackupFileNames () {
<#
.SYNOPSIS
	Reset Backup file names to current time
.DESCRIPTION
	Reset them all so that you'll be guaranteed to have the correct
	name each time
#>
	
	$Script:TE           		= Get-Date -Format yyyyMMddhhmmss # today extended
	$Script:ImportQueueFileBU  	= $Script:PSTShareDir + '\ZZSavedQueueLogs\PSTImportJobQueue' + "-" + $Script:TE + ".csv"
	$Script:CompleteQueueFileBU	= $Script:PSTShareDir + '\ZZSavedQueueLogs\PSTImportCompleteQueue' + "-" + $Script:TE + ".csv"
	$Script:ArchReportFileBU   	= $Script:PSTUNCDir   + '\ZZSavedQueueLogs\ArchiveReport-' + $Script:TE + '.csv'	
	$Script:ArchPSTFileBU     	= $Script:PSTUNCDir   + '\ZZSavedQueueLogs\ArchivePSTHistory-' + $Script:TE + '.csv'
	$Script:AllPSTFileLogBU		= $Script:PSTUNCDir   + '\ZZSavedQueueLogs\AllPSTHistory-' + $Script:TE + '.csv' 



}

#=============================================================================
#	Helper Functions
#=============================================================================
Function CC () {
<#
.SYNOPSIS
	a utility to return the count of members in a collection
.DESCRIPTION
	a utility to return the count of members in a collection
	0, 1, or many ...
#>
	
	Param (
		$Col
	)
	if ($Col) {
		if ($Col.Count -eq $null) {
			$Cnt = 1
		} Else {
			$Cnt = $Col.Count
		}
	} Else {	
		$Cnt = 0	
	}
	$Cnt
}
Function isMemberOf() {
<#
.SYNOPSIS
	A utility to check if a mailbox is a member of a group.

.DESCRIPTION
	A utility to check if a mailbox is a member of a group.
#>	
	Param (
		[string] $groupName,
		[string] $MemberName # displayname
	) 
	$m = Get-QADGroupMember $groupName -SizeLimit 0 | where { $_.Displayname -eq $memberName }
	if($m) {$true} else {$false}
	
}
Function WhoAmI () {
<#
.SYNOPSIS
	sometimes you want to know who is running this job ;)

.DESCRIPTION
	ometimes you want to know who is running this job ;)
#>
	
	([System.Security.Principal.WindowsIdentity]::GetCurrent()).Name
	
}
Function Get-ISODayOfWeek {
<#
.SYNOPSIS
	Get the correct (according to ISO 8601) day of the week

.DESCRIPTION
	For any given date you get the day of the week, according to ISO8610
	
.PARAMETER Date
	The date you want to analyze. Accepts dates on the pipeline

#>
	Param([DateTime]$date=$(Get-Date))
	Process {
	  if($_){$date=$_}
	  @(7,1,2,3,4,5,6)[$date.DayOfWeek]
	}
}
Function Get-FreeDiskSpace($drive,$computer) {
<#
.SYNOPSIS
	Utility to discover the free space of a drive

.DESCRIPTION
	Utility to discover the free space of a drive
	Used to decide if there is enough space to copy a PST file
	to either the Temp processing area, or to the local PC for backup.
#>
	
 	$driveData = Get-WmiObject -class win32_LogicalDisk -computername $computer -filter "Name = '$drive'"
	#"$computer free disk space on drive $drive"
	"{0:n2}" -f ($driveData.FreeSpace/1MB)
	
}
Function ConvertTo-ComputerName() {
<#
.SYNOPSIS
 	Resolve the IP to a computer name

.DESCRIPTION
	CAS logs record IP address for a user, but those can change over time
	resolve the IP to a computer name to save in the PST Job Queue
	- try to look up in DNS
	- 90% of time this will be an IP
	
#>    
	
	Param (
		$FindName
	)
	
    $Return = $null
	$ErrorActionPreference = "SilentlyContinue"
    $c = [System.Net.Dns]::GetHostbyAddress($FindName).HostName
	$ErrorActionPreference = "Continue"
	
	if ($c) {
    	$Return = ($c.Split(".")[0]).ToUpper()
    } Else {
		$Return = $FindName
	}
	$Return
}
Function ConvertTo-IP () {
<#
.SYNOPSIS
	Lookup IP using the ComputerName

.DESCRIPTION
	CAS logs record IP address for a user, but those can change over time
	resolve the IP to a computer name to save in the PST Job Queue
#>	
    Param ($FindName)
	
    $Return = $null
	$ErrorActionPreference = "SilentlyContinue"
	$c = [System.Net.Dns]::GetHostEntry($FindName).Addresslist[0].ToString()
	$ErrorActionPreference = "Continue"
	
	if ($c) {
    	$Return = ($c.Split(".")[0]).ToUpper()
    } Else {
		$Return = $FindName
	}
	$Return
}
Function Clean-OnlinePSTGPO(){
<#
.SYNOPSIS
	Clear up GPO group and make sure it has only the correct members

.DESCRIPTION
	Clear up GPO group and make sure it has only the correct members

.Notes
	In our world, there are 2 types of PST file users: Controled and Non-Controlled
	Controled Users:
		New users created after a certain date (1FEB2012) and Users migrated to
		Online PSTs
	Non-Controlled Users:
		Those users created befor 1FEB2012 and not having been migrated.
	
	Eventually the Non-Controlled user will disappear. At least, we can hope.
#>

	$GPO = get-group 'GPO-ReadOnlyPST' | select -ExpandProperty Members

	$GPO | %{
		
		Write-Host "Working " $_.ToString()
		$Dumpable = $false
		$Reason = "None"
		$MBX = get-mailbox $_.ToString()
				
		# Does User even have a mailbox?
		if(! (($MBX).DataBase.Name)) {
			$Dumpable = $true
			$Reason = "NoMailbox"
		}
		Elseif (!(($MBX).ArchiveDataBase.Name)) {
			#Has Mailbox but No Archive
			if ((get-date '2/1/2012') -gt (get-date ($MBX).WhenMailboxCreated)){
				$Dumpable = $true
				$Reason = "No archive and 2/1/2012 is greater than " + $(($MBX).WhenMailboxCreated)
			}
		}
		
		
		if ($Dumpable){
			#remove them from the group (GPO).
			Write-Host "Removing: " ($MBX).Displayname " - " $Reason
			Remove-QADGroupMember -Identity 'GPO-ReadONlyPST' -Member $_.ToString()
			
		}
	}
		
	# "{0,30}`t{1,10}`t{2,25}" -f (($MBX).DataBase.Name), (($MBX).ArchiveDataBase.Name),((get-date '2/1/2012') -gt ($MBX).WhenMailboxCreated)}
	
}


#=============================================================================
#	User Obj Functions - Done
#=============================================================================
Function Add-ToGPO ($User = $null) {
<#
.SYNOPSIS
	Add user to a group that defines scope of GPO to Disallow PST Growth

.DESCRIPTION
	In our organization our GPO that disallows PST growth is governed by a
	group during the transition, later we can apply that setting worldwide.
	
	For users to be comfortable, they need to Read their old PST files
	They can then check our work for themselves. #WarmAndFuzzyFactor

	These skipped users are legal discovery people that need to continue to
	create PSTs as they gather info for Lawyer types. 
		
#>	
	
	if ($User) {
		if (-not ($Script:IgnoreUser -contains (get-mailbox $User).SamAccountName)) {
			Add-QADGroupMember -Identity 'gpo-ReadonlyPST' -Member (get-mailbox $User).SamAccountName
		}
	}
	
}
Function Adjust-Quota ($User = $null) {
<#
.SYNOPSIS
	Make sure people are not hit by a quota during their transition.

.DESCRIPTION
	Make sure people are not hit by a quota during their transition Set new 
	quota to 500MB -- unless theie quota is already huge
#>
	
	if ($User) {
		$MBX = get-mailbox $User
		# what is current quota
		$UsingDBQuotas = $MBX.UseDatabaseQuotaDefaults
		if ($UsingDBQuotas -eq $True){ 
			$Database = Get-MailboxDatabase -Identity $MBX.Database
			$ProhibitSendQuota = $Database.ProhibitSendQuota.value.ToMB() -as [Int]
			$IssueWarningQuota = $Database.IssueWarningQuota.value.ToMB() -as [Int]
		
		} Else {
			$ProhibitSendQuota = $MBX.ProhibitSendQuota.value.ToMB() -as [Int]
			$IssueWarningQuota = $MBX.IssueWarningQuota.value.ToMB() -as [Int]
		}
		
		$NewProhibitSendQuota = 500 -as [int]
		$NewIssueWarningQuota = 450 -as [int]
		
		# this has bit me b4, so changed it to "-as [int]" above for better results
		if($NewIssueWarningQuota -gt $IssueWarningQuota) {
			Set-Mailbox -Identity $MBX -UseDatabaseQuotaDefaults:$False -ProhibitSendQuota 500MB -IssueWarningQuota 450MB -ProhibitSendReceiveQuota "Unlimited"
		}
	}
}
Function Get-ClientAccessUserLog () {
<#
.SYNOPSIS
	Discover a user's Client and IP information.
	
.DESCRIPTION
	Discover a user's client and IP information. Script uses this function too.
	
	There is also nightly process that runs which gets all the "connect" log 
	entries for OUTLOOK.EXE. It's run overnight. Initially we were looking at all
	the logs and that was very teadious. Now we search an already created subset.
		
	It's best to pass in the LegacyExchangeDN and SAMAccountName from the mailbox object
	from testing it seems to get better results right now using both
	
	There is no way of knowing where this user logged in so we must search
	all CAS servers until we find a "connect" entry and pass the full line back
	
	Also users can log in from many PCs -- we only want the most used
	so look thru the full day and get all info you can, then group by IP and 
	take the one with the most connects.
	
	alas, sometimes you won't find anything ...
	

#>
	param (
		$DisplayName = $null,
		$SamName = $null, 
		$LegacyName = $null, 
		$IP = $null,
		$SearchDays = 14,
		[switch]$Quiet
	)
	
	#-----------------------------------------------------------------
	
	$Results = @()
	If($DisplayName) {
		#ignore all the other cmdline entries and use this to grab those
		$MB = Get-SingleMailboxObject $DisplayName 
		$LegacyName = $MB.LegacyExchangeDN
		$SamName    = $MB.SamAccountName
	} Elseif ($IP) {
		$LegacyName = $IP
	}
		
	$Days = -1
	Do {
		$Y  = Get-Date $((get-date).adddays($Days)) -Format yyyyMMdd
		if (!($Quiet)) {Write-Host "Searching "$Y}
		if(Test-path ($Script:CASConnectLogDir + "\olConnect-"+$Y+"*")) {
			$tmpResults = gc (gci ($Script:CASConnectLogDir + "\olConnect-"+$Y+"*")) | ?{($_ -match ($LegacyName + ",")) -and ($_ -match ",,Outlook") -and ($_ -match "Connect,")}
			#Write-Verbose "Found: [$($tmpResults.count)]"
			if($tmpResults) { 
				$tmpResults | %{$Results += $_}
			}
		}
		$Days--
	} While (!($Results) -And ($Days -gt ($SearchDays * (-1))))
	
	if ($Results) {
		#split the line(s) found into Name, Version, and IP, and mode
		$c = $Results | %{"{0};{1};{2};{3}" -f $_.Split(",")[3],$_.Split(",")[6],$_.Split(",")[8],$_.Split(",")[7]}
		# this will sort the ips to the most common one, ie: users logs into 6 machines, 
		# but 1 was 12 times and all the others was 1 each, we get the 12 times
		$d = $c | %{if($_.split(";")[2]){$_.Split(";")[2]}} | group -NoElement | sort -Descending
		if($d){
			#Just give me the entries with my most common IP
			$e = $c | ?{$_ -match $d.Values}
		}
		
		#return what you found...
		if     ($e.count)   {
			# Returning 1st entry in array with ips
			$e[0]
		} Elseif ($e)         {
			# Returning only entry with ip
			$e
		} Else                {
			if ($c.count)   {
				# Returning 1st entry in array with no IP
				$c[0]
			} Else {
				# Returning only entry with no IP
				$c
			}
		}
	}
}
Function Get-MRServer ($MBX = $null) {
<#
.SYNOPSIS
	Pick an MRSServer in the same AD Site as the destination MBX Database.

.DESCRIPTION
	If you are using deticated CAS servers to import the PST files use this function
	to pick the correct one. Pick the wrong MRServer and the Import will never
	start - here I pick the an MR Server in the Same AD Site using the CAS as a
	guide we have dediticated "pst import" CAS servers.
	
	We are chosing the One CAS server we have designated to heap many request 
	upon so we don't effect user's normal performance on production CAS servers.

.NOTES
	We have since moved all our live copies of each Archive Mailboxdatabase to the
	same AD site.
	
	It is also possible to skip this step, and let exchange pick a cas server.
	Depends on how much you are moving and how you feel that will effect your users
	See "Import-PSTFromShare" 
#>
	#---------------------------------------------------------------------

	$Return = $null	
	
	#	If ($MBX) {
	#		if (((get-mailboxdatabase $mbx.database.Name).RpcClientAccessServer) -match "^ad01") {
	#			$Return = "cas02.domain.com"
	#		} Else {
	#			$Return = "cas04.domain.com"
	#		}
	#	}
	
	
	# ====> TO DO ====
	# you will need to replace this with your cas server 
	# or adjust the code above to pick the correct one
	
	$Return = "cas02.domain.com"
	
	$Return
	
}
Function Get-OutlookEXEVersion () {
<#
.SYNOPSIS
	Discover the version of Outlook on a PC

.DESCRIPTION
	Discover the version of Outlook on a PC
	
	There are many version and many people do not have a 
	compatible version with Exchange 2010 Archive Mailbox
	
	
#>
	param(
		$ComputerName = $null
	)
	
	$OL = $Null
				
	if($ComputerName) {
		if (Test-Connection -ComputerName $ComputerName -Quiet -Count 1) {
			Write-Verbose "Trying $ComputerName"
			
			If (		Test-path ('\\' + $ComputerName + '\C$\Program Files (x86)\Microsoft Office\Office14\outlook.exe')) {# office 2010 (32b) on 64bit
				Write-Verbose "Office 2010 on 64bit"
				$OL = gci ('\\' + $ComputerName + '\c$\Program Files (x86)\Microsoft Office\Office14\outlook.exe')
			} ElseIf 	(Test-path ('\\' + $ComputerName + '\c$\Program Files\Microsoft Office\Office14\outlook.exe')) {		# office 2010 on 32bit 
				Write-Verbose "Office 2010"
				$OL = gci ('\\' + $ComputerName + '\c$\Program Files\Microsoft Office\Office14\outlook.exe')
			} ElseIf 			(Test-path ('\\' + $ComputerName + '\c$\Program Files\Microsoft Office\Office12\outlook.exe')) {		# office 2007
				Write-Verbose "Office 2007"
				$OL = gci ('\\' + $ComputerName + '\c$\Program Files\Microsoft Office\Office12\outlook.exe')
			} Else {	
				#check to see if this is (oh my god!) a 2003 client
				if (Test-Path ('\\' + $ComputerName + '\c$\Program Files\Microsoft Office\OFFICE11\outlook.exe')) {
					Write-Verbose "Office 2003"
					$OL = gci ('\\' + $ComputerName + '\c$\Program Files\Microsoft Office\OFFICE11\outlook.exe')
				} Else {
					Write-Verbose "Can't determine Outlook version [$ComputerName]"	
				}
			} 
		} Else {
			Write-Warning "[$ComputerName] is not responding"
		}
	} Else {
		Write-Verbose "missing computername [$ComputerName]"	
	}
	
	$OL.VersionInfo.ProductVersion
}
Function Get-SingleMailboxObject($Name = $null) {
<#
.SYNOPSIS
	Return a single mailbox

.DESCRIPTION
	Since we are importing mail and humans can be error prone,
	make absolutely sure we only get one hit on the requested mailbox

#>
	#-----------------------------------------------------------------
		
	$ReturnMBX = $null	
	if ($Name) {
		$MBX = get-mailbox $Name -EA 0
		if (!($MBX.Count)) {			# is it less than two?
			if ($MBX) {					# is it more than zero
				$ReturnMBX = $MBX		# Return the one		
			}
		}
	}
	$ReturnMBX
}
Function New-OnlineArchiveByJob($JobObj = $null) {
<#
.SYNOPSIS
	Based on Job information, give user Online PST feature.

.DESCRIPTION
	If this job's user is not enabled for online archive
	then create one in the smallest database.
	
	The smallest DB was determined during the "add-PSTImportQueue"
	($JobObj.TargetDB)

#>	

	$Return = $false
	
	if ($JobObj) {
		$MBXObj = Get-SingleMailboxObject $JobObj.UserEmail
		
		#Write-Verbose "User DisplayName : $($mbxObj).Displayname) Derived from $($JobObj.UserEmail)"
		
		# this will either fail, create, or do nothing ;)
		Enable-Mailbox -Archive -Identity $mbxObj -ArchiveDatabase ($JobObj.TargetDB) -ArchiveName $('Online PST - ' + ($mbxObj).Displayname) -ea 0
		# just a buffer
		sleep -Seconds 5
		
		# Adjust Quota so this user is not prohibited during migration
		Adjust-Quota $MBXObj
		
		# reload to capture changes
		$MBXObj = Get-SingleMailboxObject $JobObj.UserEmail
		If ($MBXObj.ArchiveDatabase) {
			$Return = $true
			#Write-Verbose "User has Archve!"
		} Else {
			$Return = $false
			#Write-Verbose "User has NO Archve!"
		}
	}
	$Return
}
Function Test-OutlookClientVersion ($V = $null) 	{
<#
.SYNOPSIS
	Test Oulook.exe version
.DESCRIPTION
	older outlook clients can't see the "Online Archive"
	so flag those users who need an upgrade
	
	12.0.6550.5000 is the minimum level - buggy
	12.0.6607.xxxx is Office 2007 SP3 --  preferred level
		there are search bugs in earlier versions
	
	14.0.6109.5005 is outlook 14 patched to Nov 8, 2011
	14.0.6117.5xxx is patched thru April 2012 -- preferred

#>
	$VOK = $False
	if($V) {
		
		if ($V.Split(".")[0] -eq 14) {
			# Outlook 2010 (32bit)	14.0.4760.1000
			if ($V.Split(".")[2] -ge 4760) {$VOK = $true}
			
		} Elseif ($V.Split(".")[0] -eq 12) {
			# Outlook 2007 (32bit)  12.0.6550.5000 (or above)
			if ($V.Split(".")[2] -ge 6550) {$VOK = $true}
			
		}
	}
	$VOK
}


#=============================================================================
#	PST File Functions
#=============================================================================
Function Copy-PSTtoImportShare($Path=$Null, $Dest=$null){
<#
.SYNOPSIS
	copy the pst to our share folder

.DESCRIPTION
	Copy the pst to our share folder using Copy-item in the same local AD site
	works fine. Using BITS when copying over WAN lines
#>	
	
	$Result = "Fail" 	# Copied or Error(s)
	#Write-Verbose "Copy From: $Path To: $Dest"
	if($Path -and $Dest ) {
	
		$NewFile = Copy-Item -Path $Path -Destination $Dest -PassThru
		if ($NewFile){
			$Result = "Copied"
		} Else {
			# return the last error
			$Result = $error[0].Exception
			Write-Verbose "Copy ResultFrom: $($error[0].Exception)"
		}
	}
	$Result
	
}
Function Copy-PSTusingBITS ($JobObj = $null) {
<#
.SYNOPSIS
	copy the pst to our share folder

.DESCRIPTION
	Copy the pst to our share folder using Copy-item in the same local AD site
	works fine. Using BITS when copying over WAN lines
#>	
	$Result = $false
	
	if ($JobObj) {
		
		$params = @{
		    Source = ($Jobobj.OrgUNCName)
		    Destination = ($Jobobj.TargetUNCName)
		    Description = ("Online PST BITS Copy")
		    DisplayName = ($JobObj.JobName)
		    Asynchronous = $true
			Priority = "Normal"
		} 

		$Result = Start-BitsTransfer @params
		
	}
	$Result = $null
	sleep 2
	$Result = Get-BitsTransfer | Where-Object { $_.DisplayName -eq ($ThisJob.JobName) }
	$Result
}
Function Get-PSTFileList() {
<#
.SYNOPSIS
	Discover PST Files in folders
	
.DESCRIPTION
	Discover PST Files in folders
	
.NOTES	
	- Some AD objects do not have a home directory
	- Allowed for some results of *.pst being directories

#>
	param(
		$Homedir = $null, 
		$PCIP = $null, 
		$SearchPC = $false, 
		$OS = $null, 
		$UN = $null, 
		$SourceDir=$null
	)
	
	$HDFiles = $null
	$PCFIles = $null
	
	#Write-Verbose "Get-PSTFileList $HomeDir $PCIP $SearchPC $OS $UN"
	
	
	# assuming SourceDir is a specific target dir
	if(!($SearchPC) -and $SourceDir) {
			Write-host "`t-> Override HomeDir: $HomeDir to $SourceDir"
			$Homedir = $SourceDir
	}
	If ($Homedir){
		if(Test-Path $HomeDir) {
			Write-Verbose "`t`t-> Searching $HomeDir"
			# ensure this is an array even if we have only one entry
			[array]$HDFiles = gci -path $HomeDir -Filter '*.pst' -Recurse -Force -EA 0 | ?{$_.PSIsContainer -eq $false}
		}
	}
	
	
	if($SearchPC -and $PCIP) {
		if(Test-Connection $PCIP -Count 1 -Quiet) {
			
			$PCDir = $null
			if($SourceDir) {
				$PCDir = $SourceDir
			} Else {			
				if($OS -match "7") {
					Write-Verbose "`t`t-> Searching Windows7 PC $UN"
					$PCDir = $("\\" + $PCIP + "\C$\Users\" + $UN + "\AppData\Local\Microsoft\Outlook")
					
				} Elseif ($OS -match "XP") {
					Write-Verbose "`t`t-> Searching WindowsXP PC $UN"
					$PCDir = $("\\" + $PCIP + "\C$\Documents And Settings\" + $UN)
				} Else {
					#we don't know OS, so test them and see which flies
					Write-Verbose "`t`t-> OS not known, testing for OS :"
					if(Test-Path ("\\" + $PCIP + "\C$\Users\" + $UN  + "\AppData\Local\Microsoft\Outlook")) {
						Write-Verbose "`t`t-> Try Windows7"
						$PCDir = "\\" + $PCIP + "\C$\Users\" + $UN  + "\AppData\Local\Microsoft\Outlook"
					} Elseif (Test-Path ("\\" + $PCIP + "\C$\Documents And Settings\" + $UN)){
						Write-Verbose "`t`t-> Try WindowsXP"
						$PCDir = $("\\" + $PCIP + "\C$\Documents And Settings\" + $UN)
					} Else {
						Write-Verbose "`t`t-> OS Unknown"
						$PCDir = $("\\" + $PCIP + "\c$")
					}
				}
			}
			
			#if have a legit dir or just the whole c drive ...
			
			Write-Verbose "`t`t-> Searching $PCDir"
			If(Test-Path $PCDir) {
				[array]$PCFIles = gci -path ($PCDir) -Filter '*.pst' -Recurse -Force -EA 0 | ?{$_.PSIsContainer -eq $false}
			}
			
		} Else {
			Write-Output ("`t-> $PCIP is not responding.")
		}
	}
	if($HDFiles -and $PCFIles){
		$Files = $HDFiles + $PCFIles
	} Elseif ($HDFiles -and (-not $PCFIles)){
		$Files = $HDFiles
	} Elseif ((-not $HDFiles) -and $PCFIles){
		$Files = $PCFIles
	} Else {
		$Files = $null 
	}
	
	$Files
}
Function Import-PSTFromShare($JobObj){
<#
.SYNOPSIS
	import into the Archive mailbox

.DESCRIPTION
	import into the Archive mailbox
	
.NOTES
	We found that 99% of the people wanted to keep their data separate after the
	import, just like it was in their PST files, so UseTargetRootFolder was 
	defaulted to true in the NEw-PSTJobObject function
	
	We check here for false.
#>

	$Return		= "Failed"
	$Error.Clear | Out-Null	
	$MBXName	= $JobObj.UserObj
	$User       = $JobObj.UserObj.Split("\")[1]
	$File 		= $JobObj.TargetUNCName
	$JobName	= $JobObj.JobName
	$CAS		= $JobObj.MRServer
	if ($JobObj.TargetRootFolder) {
		$Folder = $JobObj.TargetRootFolder
	} Else {
		$Folder = $JobObj.OrgFileName
	}
	
	Write-Debug "$MBXName -Name  $JobName  -Batchname  $USER  -MRSServer  $CAS -TargetDB   $JobObj.TargetDB"
	
	# import the pst
	#======= TO DO ============
	# remove the -MRSServer $CAS - if you want Exchange to choose the CAS server every time.
	
	if($JobObj.UseTargetRootFolder -eq "TRUE") {
		$PSTQueued = New-MailboxImportRequest -Name $JobName -BatchName $USER -Mailbox "$MBXName" -FilePath "$File" -IsArchive -MRSServer $CAS -BadItemLimit 9999 -AcceptLargeDataLoss -Confirm:$false -targetrootfolder $Folder
	} Else {
		$PSTQueued = New-MailboxImportRequest -Name $JobName -BatchName $USER -Mailbox "$MBXName" -FilePath "$File" -IsArchive -MRSServer $CAS -BadItemLimit 9999 -AcceptLargeDataLoss -Confirm:$false
	}
	If($PSTQueued) {
		$Return = $PSTQueued.Status
	} Else { 
		$Return = $Error[0].ToString()
	}
	sleep -Seconds 5
	$Return
}
Function Move-PSTToLocal ($IP=$null, $PSTFiles=$null, $SamAcct=$null, $IgnoreAge=$False) {
<#
.SYNOPSIS
	clear PST files off the Home shares
	
.DESCRIPTION
	The botton line of this project is to clear PST files off the Home shares
	If the PST file has been imported the file itself has become a backup
	and as such is safe to put on the local PC of the user.
	
.NOTES
	Move PSTs
	If this is a windows 7 box and has 2010 this might be the place to put them
	  \\172.18.20.1\c$\Users\<user>\Documents\Outlook Files	
	
	but this is good for XP	
	  \\172.18.20.1\c$\D9ocuments and Settings\<user>\My Docuemtns\Outlok Files
	
	If this user is in a far away place, then do NOT push the data back to the PC

#>	
	
	
	Write-Host "Starting = Who:($SamAcct), Count:($(($PSTFiles).Count)), Computer:($IP)" 
	
	$HQUser = $true
	$Region = (get-mailbox $SamAcct).CustomAttribute2
	If (($Region -eq "Asia") -or ($Region -eq "Europe")) {$HQUser = $false}
	if ($IP -eq "None") {$IP = $null}
	
	if($IP -and $PSTFIles -and $SamAcct -and $HQUser) {
		#make sure we can ping the PC
		Write-Host $("$SamAcct; Starting Move-PSTFiles $(get-date)")
		$("$SamAcct; Starting Move-PSTFiles $(get-date)") >> $Script:MoveFileLog
		if (Test-Connection -ComputerName $IP -Quiet){
			
			Write-Host $("$SamAcct; Connect to $IP passed")
			$("$SamAcct; Connect to $IP passed") >> $Script:MoveFileLog
			
			# both return MB
			$AvailableSpace = [int](get-freediskspace 'c:' $IP)/2
			$PSTFiles		= $PSTFiles | Sort Length
			$PSTSize        = (($PSTFIles | Measure-Object Length -sum).Sum)/(1024*1024)
			$OldPSTSize		= ((($PSTFIles | ?{$_.LastWriteTime -le (get-date ((get-date).adddays(-90))) } | Measure-Object Length -sum).Sum)/(1024*1024))
	
			$Continue = $false
			if (Test-Path $('\\' + $IP + '\c$\users\' + $SamAcct)) {
				
				# Put them in this dir structure, create or use Outlook Files dir
				$LocalBU = $('\\' + $IP + '\c$\users\' + $SamAcct+ '\Documents\Outlook Files')
				if (!(Test-Path $LocalBU)){ mkdir $LocalBU }
				$Continue = $true
				Write-Host $("$SamAcct; Connect to $IP passed")
				$("$SamAcct; LocalBU is $LocalBU") >> $Script:MoveFileLog
				
			} Elseif (Test-Path $('\\' + $IP + '\c$\documents and settings\' + $SamAcct)) {
			
				# Put them in this dir structure, create or use Outlook Files dir
				$LocalBU = $('\\' + $IP + '\c$\documents and settings\' + $SamAcct + '\Outlook Files')
				if (!(Test-Path $LocalBU)){ mkdir $LocalBU }
				$Continue = $true
				Write-Host $("$SamAcct; LocalBU is $LocalBU")
				$("$SamAcct; LocalBU is $LocalBU") >> $Script:MoveFileLog
				
			} Else {
				# crap! i give up...
				#I hope i have the right IP -- log it
				Write-Host "Can not find a secure directory for $SamAcct"
				$Continue = $false
				$("$SamAcct; LocalBU is Can not find a secure directory; Fail") >> $Script:MoveFileLog
				
			}
			
			
			
			if ($Continue) {	
				# move the files
				$FileNames = @()
				$PSTFiles | %{
					$ThisPST = $_
					$FN = $ThisPST.Name
					$PSTBackups = $LocalBU
					$FileAge = (((get-date) - ($ThisPST.LastWriteTime)).Days)
					
					Write-Host "Working: $FN"
					Write-Host "(($AvailableSpace) -gt ($PSTSize))"
					Write-Host "IgnoreAge is $IgnoreAge"
					if($AvailableSpace -gt $PSTSize) {
						# there is enough space on the drive to hanlde all the PSTs
						
						If($IgnoreAge) {
							# if we are moving a lot of files, many can be named the same, as in backups and crap like that
							# so allow by adding a random number to the filename
							if($FileNames -contains $FN -or (Test-Path $($PSTBackups + "\" + $FN))){
								#rename it in the move
								$rn = "{0:00}" -f (Get-Random -maximum 10000)
								[string]$FN = $ThisPST.Name.Split(".")[0] + "-" + $RN  + "." + ($ThisPST.Name.Split(".")[1])
								$PSTBackups = $PSTBackups + "\" + $FN
								$("$SamAcct; Moving $($ThisPST.VersionInfo.Filename) -Destination  $($PSTBackups)") >> $Script:MoveFileLog
								Write-Host "Moving $($ThisPST.VersionInfo.Filename) -Destination  $($PSTBackups)" 
								#Read-Host "Continue"
								Move-Item -Path $($ThisPST.VersionInfo.Filename) -Destination  $($PSTBackups)
							} Else {
								# Just Move It Move It
								$PSTBackups = $PSTBackups + "\" + $FN
								$("$SamAcct; Age [$($FileAge)] Moving $($ThisPST.VersionInfo.Filename) -Destination  $($PSTBackups)") >> $Script:MoveFileLog
								Write-Host "Age [$($FileAge)] Moving $($ThisPST.VersionInfo.Filename) -Destination  $($PSTBackups)" 
								#Read-Host "Continue"
								Move-Item -Path $($ThisPST.VersionInfo.Filename) -Destination  $($PSTBackups)
							}
						} Else {
							#don't move if younger than 30 days
							If ($ThisPST.LastWriteTime -le (get-date ((get-date).adddays(-30)))){
								#meaning it's older, so move it

								# if we are moving a lot of files, many can be named the same, as in backups and crap like that
								# so allow by adding a random number to the filename
								if($FileNames -contains $FN -or (Test-Path $($PSTBackups + "\" + $FN))){
									#rename it in the move
									$rn = "{0:00}" -f (Get-Random -maximum 10000)
									[string]$FN = $ThisPST.Name.Split(".")[0] + "-" + $RN  + "." + ($ThisPST.Name.Split(".")[1])
									$PSTBackups = $PSTBackups + "\" + $FN
									$("$SamAcct; Age [$($FileAge)] Moving $($ThisPST.VersionInfo.Filename) -Destination  $($PSTBackups)") >> $Script:MoveFileLog
									Write-Host "Age [$($FileAge)] Moving $($ThisPST.VersionInfo.Filename) -Destination  $($PSTBackups)" 
									#Read-Host "Continue"
									Move-Item -Path $($ThisPST.VersionInfo.Filename) -Destination  $($PSTBackups)
								} Else {
									# Just Move It Move It
									$PSTBackups = $PSTBackups + "\" + $FN
									$("$SamAcct;Age [$($FileAge)] Moving $($ThisPST.VersionInfo.Filename) -Destination  $($PSTBackups)") >> $Script:MoveFileLog
									Write-Host "Age [$($FileAge)] Moving $($ThisPST.VersionInfo.Filename) -Destination  $($PSTBackups)" 
									#Read-Host "Continue"
									Move-Item -Path $($ThisPST.VersionInfo.Filename) -Destination  $($PSTBackups)
								}
							} Else {
								# file is too young
								$("$SamAcct; Age [$($FileAge)] Skipping due to Age<30 $($ThisPST.VersionInfo.Filename) -Destination  $($PSTBackups)") >> $Script:MoveFileLog
								Write-Host "Age [$($FileAge)] Skipping due to Age<30  $($ThisPST.VersionInfo.Filename) -Destination  $($PSTBackups)"
							}
						}
					} Else {
						# there is NOT enough space on the drive to handle all the PSTs
						
						# Psts are sorted by smallest to largest so do what you can
						$AvailableSpace = [int](get-freediskspace 'c:' $IP)/2
						$PSTSize        = (($ThisPST | Measure-Object Length -sum).Sum)/(1024*1024)
						If($AvailableSpace -gt $PSTSize) {
							Write-Host "(($AvailableSpace) -gt ($PSTSize))"
							If($IgnoreAge) {
												
									# if we are moving a lot of files, many can be named the same, as in backups and crap like that
									# so allow by adding a random number to the filename
									if($FileNames -contains $FN -or (Test-Path $($PSTBackups + "\" + $FN))){
										#rename it in the move
										$rn = "{0:00}" -f (Get-Random -maximum 10000)
										[string]$FN = $ThisPST.Name.Split(".")[0] + "-" + $RN  + "." + ($ThisPST.Name.Split(".")[1])
										$PSTBackups = $PSTBackups + "\" + $FN
										$("$SamAcct; Age [$($FileAge)] Moving $($ThisPST.VersionInfo.Filename) -Destination  $($PSTBackups)") >> $Script:MoveFileLog
										Write-Host "Age [$($FileAge)] Moving $($ThisPST.VersionInfo.Filename) -Destination  $($PSTBackups)" 
										#Read-Host "Continue"
										Move-Item -Path $($ThisPST.VersionInfo.Filename) -Destination  $($PSTBackups)
									} Else {
										# Just Move It Move It
										$PSTBackups = $PSTBackups + "\" + $FN
										$("$SamAcct; Age [$($FileAge)] Moving $($ThisPST.VersionInfo.Filename) -Destination  $($PSTBackups)") >> $Script:MoveFileLog
										Write-Host "Age [$($FileAge)] Moving $($ThisPST.VersionInfo.Filename) -Destination  $($PSTBackups)" 
										#Read-Host "Continue"
										Move-Item -Path $($ThisPST.VersionInfo.Filename) -Destination  $($PSTBackups)
									}
							} Else {
								#don't move if younger than 90 days
								If ($ThisPST.LastWriteTime -le (get-date ((get-date).adddays(-30)))){
									#meaning it's older, so move it

									# if we are moving a lot of files, many can be named the same, as in backups and crap like that
									# so allow by adding a random number to the filename
									if($FileNames -contains $FN -or (Test-Path $($PSTBackups + "\" + $FN))){
										#rename it in the move
										$rn = "{0:00}" -f (Get-Random -maximum 10000)
										[string]$FN = $ThisPST.Name.Split(".")[0] + "-" + $RN  + "." + ($ThisPST.Name.Split(".")[1])
										$PSTBackups = $PSTBackups + "\" + $FN
										$("$SamAcct; Age [$($FileAge)] Moving $($ThisPST.VersionInfo.Filename) -Destination  $($PSTBackups)") >> $Script:MoveFileLog
										Write-Host "Age [$($FileAge)] Moving $($ThisPST.VersionInfo.Filename) -Destination  $($PSTBackups)" 
										#Read-Host "Continue"
										Move-Item -Path $($ThisPST.VersionInfo.Filename) -Destination  $($PSTBackups)
									} Else {
										# Just Move It Move It
										$PSTBackups = $PSTBackups + "\" + $FN
										$("$SamAcct; Age [$($FileAge)] Moving $($ThisPST.VersionInfo.Filename) -Destination  $($PSTBackups)") >> $Script:MoveFileLog
										Write-Host "Age [$($FileAge)] Moving $($ThisPST.VersionInfo.Filename) -Destination  $($PSTBackups)" 
										#Read-Host "Continue"
										Move-Item -Path $($ThisPST.VersionInfo.Filename) -Destination  $($PSTBackups)
									}
								} Else {
									# file is too young
									$("$SamAcct; Age [$($FileAge)] Skipping due to Age<30 $($ThisPST.VersionInfo.Filename) -Destination  $($PSTBackups)") >> $Script:MoveFileLog
								}
							}
						} Else {
							$("$SamAcct; Age [$($FileAge)] Skipping due to AvailableSpace $($ThisPST.VersionInfo.Filename) -Destination  $($PSTBackups)") >> $Script:MoveFileLog
						}
					}
					$FileNames += $FN
				}
				
			} Else {
				Write-Host "No Files Moved."
				$("$SamAcct; No Files Moved.") >> $Script:MoveFileLog
			}
		} Else {
			Write-Host "Computer [$IP] seems dead"
			$("$SamAcct; Computer [$IP] seems dead.") >> $Script:MoveFileLog
		}
	} Else {
		if (!($PSTFiles)) {
			Write-Host "No PST Files found."
			$("$SamAcct; No PST Files found.") >> $Script:MoveFileLog
		} Else {
				Write-Host "Bad Parameters or Not CONUS User."
			$("$SamAcct; Bad Parameters or Not CONUS User.") >> $Script:MoveFileLog
		}
	}
}


#=============================================================================
#	PST Queue Functions
#=============================================================================
Function Format-JobStatus($JobObj) {
<#
.SYNOPSIS
	Query the queue for info on a particular user.
.DESCRIPTION
	Query the queue for info on a particular user.
	
	Count the number of jobs in each status category, incoming JobObj is a 
	collection.
#>
	#
	# 
	#
	# 
	
	$JobsCount       = 0
	$StatusNew       = 0
	$StatusCopied    = 0
	$StatusBITS      = 0
	$StatusInQueue   = 0
	$StatusImported  = 0
	$StatusCleanedup = 0
	$StatusNotified  = 0
	$LastError       = $null
	$JobSize         = 0
	$StatusSkipped	 = 0
	
	$JobObj | %{
	
		$ClientOK = $_.ClientVerOK
		$UName =  $_.UserMBX
		$TargetDB = $_.TargetDB
		$a = [int]($_.FileSize)
		$JobSize += $a
		$skip=$false
		if(($_.ProcessFile -eq "FALSE")){$Skip=$true}
		
		
		Switch ($_.JobStatus) {
			New {
				if(($Skip)){$StatusSkipped++} Else {$StatusNew++}
			}
			NewBits {
				if(($Skip)){$StatusSkipped++} Else {$StatusNew++}
			}
			Copied {$StatusCopied++}
			InBits {$StatusBITS++}
			InQueue {$StatusInQueue++}
			Imported {$StatusImported++}
			CleanedUp {$StatusCleanedup++}
			Notified {$StatusNotified++}
		}
		$JobsCount++
	}
	$StatusEntry = New-Object PSObject
	$StatusEntry | Add-Member -type NoteProperty -name Name      	-value ($UName)
	$StatusEntry | Add-Member -type NoteProperty -name Client    	-value ($ClientOK)
	$StatusEntry | Add-Member -type NoteProperty -name Size		   	-value ($JobSize)
	$StatusEntry | Add-Member -type NoteProperty -name Jobs      	-value ($JobsCount)
	$StatusEntry | Add-Member -type NoteProperty -name New      	-value ($StatusNew)
	$StatusEntry | Add-Member -type NoteProperty -name Skip      	-value ($StatusSkipped)
	$StatusEntry | Add-Member -type NoteProperty -name BITS      	-value ($StatusBITS)
	$StatusEntry | Add-Member -type NoteProperty -name Copied      	-value ($StatusCopied)
	$StatusEntry | Add-Member -type NoteProperty -name InQue     	-value ($StatusInQueue)
	$StatusEntry | Add-Member -type NoteProperty -name Imptd    	-value ($StatusImported)
	$StatusEntry | Add-Member -type NoteProperty -name ClndUp   	-value ($StatusCleanedup)
	$StatusEntry | Add-Member -type NoteProperty -name Notifd 	   	-value ($StatusNotified)
	$StatusEntry | Add-Member -type NoteProperty -name Target 	   	-value ($TargetDB)
	#$StatusEntry | Add-Member -type NoteProperty -name Errors      	-value ($LastError)
	
	$StatusEntry
}
Function Get-ArchDB() {
<#
.SYNOPSIS
	Find the smallest Archive mailbox database
.DESCRIPTION
	Find the smallest Archive mailbox database, not necesarily the smallest now, 
	but even after all the current jobs are processed
#>
	
	#get current sizes - include or exclude certain DBs
	$ArchSize = @{}
	# get all database that Start with "arch", 3 digits, and end with character "b-z" like "Arch101B" for example
	# excluding arch102* for now, no more users there...
	(get-mailboxdatabase |?{$_.name -match 'arch\d{3}[acdef]' -and $_.name -notmatch 'arch102'} | Get-MailboxDatabase -Status) | %{$ArchSize.Add($_.Name, $_.DatabaseSize.ToMB())}
	
	# need to account for pending items...
	if($OldJobQueue) {
		$OldJobQueue | %{
			$tmp = $ArchSize.item($_.TargetDB)
			$Tmp += [int]$_.FileSize
			$ArchSize.remove($_.TargetDB)
			$ArchSize.add($_.TargetDB, $tmp)
		}
	}
	
	# return the smallest one
	($ArchSize.GetEnumerator() | sort Value)[0].Name
}
Function Lock-PSTIQ() {
<#
.SYNOPSIS
	Signal the queue file is in use by creating a file.

.DESCRIPTION
	Signal the queue file is in use by creating a file.
	
#>
	if(!(Test-PSTIQLock)) {$a = New-Item $($Script:PSTUNCDir + '\PSTImportQueue.Lock') -itemtype "file"}
}
Function New-TargetPSTDirectory($MBX = $null) {
<#
.SYNOPSIS
	Create a directory to hold the PST file while they are importing.
	
.DESCRIPTION
	Create a directory to hold the PST file while they are importing.
	These psts are deleted at the end, but reports for each PST file
	are left in the directory.
#>
	$Return = "Error"

	If ($MBX) {
		$dir    = $Script:PSTShareDir + "\" + $MBX.samaccountname
		if(!(Test-Path $dir)) {
			$newdir = ni -ItemType Directory -Path $dir
		} Else {
			$Return = $dir
		}
	}
	
	#Test new dir and make sure it's there
	If($newdir) {
		$Return = (resolve-path $newdir).ProviderPath
	}
	$Return
}
Function Test-PSTIQLock () {
<#
.SYNOPSIS
	Test to see if PST Import Queue is in use.
.DESCRIPTION
	Test to see if PST Import Queue is in use.
#>
	Test-Path $($Script:PSTUNCDir + '\PSTImportQueue.Lock')
}
Function Unlock-PSTIQ() {
<#
.SYNOPSIS
	Remove the lock when the PST Import Queue is no longer in use.

.DESCRIPTION
	Remove the lock when the PST Import Queue is no longer in use.
#>
	if(Test-PSTIQLock) {Remove-Item $($Script:PSTUNCDir + '\PSTImportQueue.Lock')}
}

#=============================================================================
#	Send Notification Functions
#=============================================================================
Function Send-NotificationInitialReport($JobObj) {
<#
.SYNOPSIS
	Send the User a notification of PST files found and the work to be done.

.DESCRIPTION
	Send the User a notification of PST files found and the work to be done.
	Incoming JobObj will give us the information we needed to the report.

#>
	$AllProcessFiles   = $JobObj | ?{$_.ProcessFile -eq $true}
	$AllSkippedJobs	   = $JobObj | ?{$_.ProcessFile -ne $true}
	$JobObj | %{$User = $_.UserMBX; $CLOK = $_.ClientVerOK }
	
	Write-Host $User
	Write-Host $CLOK
	$Subject = "Requested PST Import: Initial Report for " + $User
	$From    = "EmailTeam@domain.com"
	
	$Body = "Note: This process will not delete or alter your original PSTs in any way.`n"
	if ($JobObj.ClientVer -match "^14.") {
		$Body	= $Body + "Your offline PST files will be copied into your new " + '"Archive - ' + $JogObj.UserEmail + '"' + " folder in Outlook.`n"
	} Else {
		$Body	= $Body + "Your offline PST files will be copied into your new " + '"Online PST"' + " folder in Outlook.`n"
	}
	$Body	= $Body + "`n"
	$Body	= $Body + "The copy may take a few nights to complete. The process will start tonight about 7PM (1900). `n"
	$Body	= $Body + "`t- Do not add any messages to your PSTs during this process.`n"
	$Body	= $Body + "`t- Please shut down Outlook before leaving each night.`n"
	$Body	= $Body + "`t- You do not need to turn off your PC.`n"
	$Body	= $Body + "`n"
	$Body	= $Body + "You will be notified when the copies are complete.`n"
	$Body	= $Body + "`n"
	# you may want to comment this out, or create one of your own
	#$Body	= $Body + "Click below to read the FAQ about Online PSTs."
	#$Body	= $Body + "`n"
	#$Body	= $Body + '"' + 'http://<link to self help doc on sharepoint>
	#$Body	= $Body + "`n"
	$Body	= $Body + "Once you see your new Online PST, use it as you would any PST.`n"
	$Body	= $Body + "`n"
	$Body	= $Body + "The procedure for finding your PST files has finished and found " + $JobObj.Count + " files. The ones scheduled for import, are:`n`n"

	#location of How to remove password on PST
	#"`n(http://office.microsoft.com/en-us/outlook-help/remove-a-password-from-a-personal-folders-file-pst-HA001151725.aspx)"
	
	if ($AllProcessFiles) {
		$NUm = 0
		$tmp = $null
		$tmp = "{0,3}`t{1,-25}`t{2}`t`t{3}`n" -f ("Num"),("FileName"),("Size"),("Directory")
		$Body	= $Body + $tmp
		$AllProcessFiles | %{
			$NUm++
			$To		= $_.UserEmail
			$temp	= '"' + (split-path $_.OrgUNCName) + '"'
			$temp1	= $_.OrgFileName
			$tempS	= $_.FileSize
			$tmp = $null
			$tmp = "{0,3}`t{1,-25}`t({2,7} M)`t{3}`n" -f ($Num),($temp1),($tempS), ($temp)
			$Body	= $Body + $tmp	
		}
	} Else {
		$Body	= $Body + "(None)"
	}
	$Body	= $Body + "`n`nSkipped Files: `n"
	
	if($AllSkippedJobs) {
		$NUm = 0
		$tmp = $null
		$tmp = "{0,3}`t{1,6}`t{2,-25}`t{3}`t`t{4}`n" -f ("Num"),("Reason"),("FileName"),("Size"),("Directory")
		$Body	= $Body + $tmp
		$AllSkippedJobs | %{
			$NUm++
			$To		= $_.UserEmail
			$temp	= '"' + (split-path $_.OrgUNCName) + '"'
			$temp1	= $_.OrgFileName
			$tempS	= $_.FileSize
			$skip   = $_.SkipReason
			$tmp = $null
			$tmp = "{0,3}`t{1,6}`t{2,-25}`t({3,7} M)`t{4}`n" -f ($Num),($skip),($temp1),($tempS),($temp)
			$Body	= $Body + $tmp
		}
	} Else {
		$Body	= $Body + "(None)"
	}
	
	$Body	= $Body + "`n`n"
	$Body	= $Body + "Files are skipped due to either size (empty file) or not opened by Outlook in the last 2 years.`n"
	$Body	= $Body + "Files also can be skipped if they look like Backups (BU) or Sharepoint Lists (SP).`n"
	$Body	= $Body + "(Skipping files is just a suggestion. You can opt to include them.)`n"
	
		
	if($JobObj.Count){
		$Body	= $Body + "`n[Run on: " + $(Hostname) + "; Client is " + (($JobObj)[0].ClientVerOK) + " " + (($JobObj)[0].ClientVer) + "]["+(($JobObj)[0].IP)+"]["+(($JobObj)[0].OSName)+"]"
		
	} Else {
		$Body	= $Body + "`n[Run on: " + $(Hostname) + "; Client is " + (($JobObj).ClientVerOK) + " " + (($JobObj).ClientVer) + "]["+(($JobObj).IP)+"]["+(($JobObj).OSName)+"]"
		
	}
	If ($NoNotify) {
		Send-MailMessage -Body $body -From $From -SmtpServer $Script:SMTPServer -Subject $Subject -To $Script:AdminEmail
	} Else {
		Send-MailMessage -Body $body -To $To -From $From -SmtpServer $Script:SMTPServer -Subject $Subject -cc $Script:AdminEmail
		#Send-MailMessage -Body $body -To $JobObj.UserEmail -From $From -SmtpServer $Script:SMTPServer -Subject $Subject
	}
	

}
Function Send-NotificationFinalReport($JobObj) {
<#
.SYNOPSIS
	Send User the Final report detailing the work done.

.DESCRIPTION
	Send User the Final report detailing the work done.

#>
	$AllProcessFiles   = $JobObj | ?{$_.ProcessFile -eq "TRUE"}
	$AllSkippedJobs	   = $JobObj | ?{$_.ProcessFile -eq "FALSE"}
	
	if($JobObj.Count) {
		$Subject   = "Requested PST Import: Final Results for: " + $JobObj[0].UserMBX
		$ClientVer = $JobObj[0].ClientVer
		$Email     = $($JobObj[0].UserEmail.ToString())
	} Else {
		$Subject = "Requested PST Import: Final Results for: " + $JobObj.UserMBX
		$ClientVer = $JobObj.ClientVer
		$Email     = $($JobObj.UserEmail.ToString())
	}
	
	$From    = "EmailTeam@domain.com"
	
	
	$Body	= "The process for copying your PST files has finished.  Please take a few moments to complete the final steps:`n"
	$Body	= $Body + "`n"
	if ($ClientVer -match "^14." -or $ClientVer -match "Ignore") {
		$Body	= $Body + "`t1. Review messages in the " + '"Archive - ' + $Email + '"' + " folder in Outlook and confirm all have been copied correctly.`n"
	} Else {
		$Body	= $Body + "`t1. Review messages in the " + '"Online PST"' + " folder in Outlook and confirm all have been copied correctly.`n"
	}
	#$Body	= $Body + "`t1. Review messages in the " + '"Online PST - <yourname>" or "Archive - <yourname>"' + " folder in Outlook and confirm all have been copied correctly.`n"
	
	
	$Body	= $Body + "`t2. Disconnect the old PSTs from Outlook. (right click the name and choose: Close <pstname>)`n"
	$Body	= $Body + "`t3. Restart Outlook - to release the lock on the file.`n"
	$Body	= $Body + "`t4. Move the old PST files from your Home Drive (H:\) to a local drive. This will improve your Outlook performance!`n"
	$Body	= $Body + "`t   (For example, create a directory in " + '"My Documents"' + " called " + '"Outlook Files"' + " and move the files listed below from your H:\ to the new Outlook Files directory.)`n"
	
	if ($ClientVer -match "^14." -or $ClientVer -match "Ignore") {
		$Body	= $Body + "`t5. Begin storing messages in your " + '"Archive - ' + $Email + '"' + " folder instead of your old PSTs.`n"
	} Else {
		$Body	= $Body + "`t5. Begin storing messages in your " + '"Online PST"' + " folder instead of your old PSTs.`n"
	}
	#$Body	= $Body + "`n`tFor detailed instructions, click this link:`n"
	#$Body	= $Body + "`n`t" + '"http://<sharepointsite>/Self-Help/Standard Application Issues/How do I Disconnect My Personal Folders.pdf"' + "`n"
	#$Body	= $Body + "`n"
	
	$Body	= $Body + "`tNote: Remember you can read your old PSTs at any time. In a few days you will not be able to add any new emails to these old PST files.`n"
	$Body	= $Body + "`t      You are now using the Online PST instead.`n"
	$Body	= $Body + "`n"
	$Body	= $Body + "`nThe files which can be moved off your home drive:`n"
	$Body	= $Body + "`n"
	$Body	= $Body + "`nIf you need assistance or have any questions, simply reply-all to this email.`n"
	$Body	= $Body + "`n"
	$Body	= $Body + "Imported Files:`n"
	$NUm = 0
	$tmp = "{0,3}`t{1,-40}`t{2,-35}`t{3}`t{4}`n" -f ("Num"),("FileName"),("Target Folder"),("Size"),("Directory")
	$Body	= $Body + $tmp
	$AllProcessFiles | %{
		$NUm++
		$To		=  $_.UserEmail
		$temp	= '"' + (split-path $_.OrgUNCName) + '"'
		$temp1	= $_.OrgFileName
		$tempS	= $_.FileSize
		$tempT  = $_.TargetRootFolder
		$tmp = $null
		$tmp = "{0,3}`t{1,-40}`t{2,-35}`t({3,7} M)`t{4}`n" -f ($Num),($temp1),($tempT),($tempS),($temp)
		$Body	= $Body + $tmp	
		
	}
	
	$Body	= $Body + "`n`nSkipped Files:`n"
	
	if($AllSkippedJobs) {
		$NUm = 0
		$tmp = $null
		$tmp = "{0,3}`t{1,6}`t{2,-40}`t{3}`t`t{4}`n" -f ("Num"),("Reason"),("FileName"),("Size"),("Directory")
		$Body	= $Body + $tmp
		$AllSkippedJobs | %{
			$NUm++
			$To		= $_.UserEmail
			$temp	= '"' + (split-path $_.OrgUNCName) + '"'
			$temp1	= $_.OrgFileName
			$tempS	= $_.FileSize
			$skip   = $_.SkipReason
			$tmp = $null
			$tmp = "{0,3}`t{1,6}`t{2,-40}`t({3,7} M)`t{4}`n" -f ($Num),($skip),($temp1),($tempS),($temp)
			$Body	= $Body + $tmp
		}
	} Else {
		$Body	= $Body + "(None) "
	}
	
	#$Body	= $Body + "`n`nIf you have any questions, reply to this email."
	$Body	= $Body + "`n"
	$Body	= $Body + "`Thank You -- The Email Group"
	$Body	= $Body + "`n"
	
	if($JobObj.Count){
		$Body	= $Body + "`n[Run on: " + $(Hostname) + "; Client is " + (($JobObj)[0].ClientVerOK) + " " + (($JobObj)[0].ClientVer) + "]["+(($JobObj)[0].IP)+"]["+(($JobObj)[0].OSName)+"]"
		
	} Else {
		$Body	= $Body + "`n[Run on: " + $(Hostname) + "; Client is " + (($JobObj).ClientVerOK) + " " + (($JobObj).ClientVer) + "]["+(($JobObj).IP)+"]["+(($JobObj).OSName)+"]"
		
	}
	
	Send-MailMessage -Body $body -To $To -From $From -SmtpServer $Script:SMTPServer -Subject $Subject -Cc $Script:AdminEmail
	

}
Function Send-NotificationPSTRemoval() {
<#
.SYNOPSIS
	Send user a report showing the files that are still 'connected' to Outlook

.DESCRIPTION
	Send user a report showing the files that are still 'connected' to Outlook
	Connected means the LastWriteTime was within the last 24 hours.
	
	User gets this email every 14 days as a reminder to disconnect their Old
	PST files and optionaly remove those PST files from Home Share.

#>	
	#------------------------------------------------------------------------
	
	Param(
		$ArchObj, 
		[array]$PSTFilesInUse,
		[array]$PSTFilesALL,
		[array]$PSTFilesMovable
	)
	
	
	$Subject = "Online PST -- Possible Outlook Issue : " + $ArchObj.DisplayName + " (" + $ArchObj.DaysSinceImport + ")"
	$From    = "EmailTeam@domain.com"
	$To 	 = $((get-mailbox $ArchObj.DisplayName).PrimarySMTPAddress.ToString())
	$CC      = $Script:AdminEmail
	
	[int]$InUse   = cc $PSTFilesInUse; 		Write-Verbose "[SendNotification] Inuse  - $InUse"
	[int]$AllPSTs = cc $PSTFilesALL; 		Write-Verbose "[SendNotification] AllPST - $AllPSTs"
	[int]$Movable = cc $PSTFilesMovable;	Write-Verbose "[SendNotification] AllPST - $AllPSTs"
	
	#grab this user's latest client version
	$Vers = (import-csv $Script:PSTCompleteFile | ?{$_.UserMBX -match ($ArchObj.DisplayName)} | sort LastCheckTime -Descending)
	
	If ($Vers.Count) {
		$ClientVer = $Vers[0].ClientVer
	} Else {
		If ($Vers){
			$ClientVer = $Vers.ClientVer
		} Else {
			$ClientVer = "Ignore"
		}
	}
	Write-Verbose "[SendNotification] $(($ArchObj).DisplayName) : Client Ver is $($ClientVer)"
	
	If ($ClientVer -match "^14." -or $ClientVer -match "Ignore") {
		$Archive =
