#Requires -version 5.0
<#
.SYNOPSIS
	Archives and deletes files on the basis of an ISO 8601 date (YYYY-MM-DD) in the first ten bytes of the file name.
.DESCRIPTION
	This script processes only files in the source directory with an ISO date as the first ten bytes of the file name.
	Based on that ISO date, :
	a)	if the file date is equal to or older than the supplied archive age in days: 
		compress all files with the same ISO date to a single .ZIP file, 
	b)	if the file date is equal to or older than the supplied deletion age in days: 
		delete the file. (Deletion can be disabled by changing the value of the variable $NoDel from 0.)
	A log file is produced and that is also sent via email to one or more recipients.
.PARAMETER SrcDir
    Mandatory. 
	The directory to be searched for files that are candidates for archiving and/or deletion.
.PARAMETER DstDir
    Mandatory. 
	The directory where archives (.ZIP files) are to be written.
.PARAMETER LogDir
    Mandatory. 
	The directory where script execution log file is to be written.
.PARAMETER ArcAge
    Mandatory. The age, in number of days prior to today, of files to be archived. 
	Must be greater than or equal to 1 AND less than DelAge.
.PARAMETER DelAge
    Mandatory. The age, in number of days prior to today, of files to be deleted. 
	Must be greater than ArcAge.
.INPUTS
    a)	One or more files, stored in SrcDir, with an ISO date (YYYY-MM-DD) beginning their file names.
	b)	A file containing the addressees for the script log email. 
.OUTPUTS
    a)	One or more ZIP files, written to DstDir and named "YYYY-MM-DD.zip";
		where YYYY-MM-DD is the date of all files from SrcDir with a matching ISO date. 
    b)	A log file, written to LogDir, named "YYYY-MM-DD_HH-MM-SS.log";
		where YYYY-MM-DD_HH-MM-SS is the start date and time.
    c) 	Send an email with the contents of the log file to the addressees in DistList.
.NOTES
	Version:        	1.4
	Author:         	PhilB
	Creation Date:  	2015-08-30
	Modification Date:	2016-01-01	Get email distribution list from DistList
						2016-03-23	Restructure and add calls to 7zip to replace buggy Compress-Archive
						2016-04-27	Remove dependency on external logging script; 
									Add runtime and bytes archived to log file.
						2016-05-01	Reinstated missing -mx1 parameter on the call to 7za; 
									Reverted to compressing all files with the same date in one pass.
    Performance Notes:
	a)	For best performance, all files with the same $FileDate are processed with one invocation of the compression method.
		Compressing one file at a time costs about 50% increase in run time. (It's commented out in the body of script.)
		CODE:	$cmd = "C:\PowerShell\7za.exe a -tzip $($DstDir + "\" + $FileDate) $($SrcDir + "\" + $FileDate.Name) -mx1"; Invoke-Expression $cmd

		An alternative to the $cmd/Invoke-Expression method used above: 
		CODE:	Compress-Archive -Path $($SrcDir + "\" + $FileDate + "*") -DestinationPath $($DstDir + "\" + $FileDate + ".zip")
		ISSUE:	This is purest/cleanest but, with PS v5.0
				- won't work with files larger than about 1 GB 
				- does not preserve original file Modified date and time within the ZIP file. 

	b)	The Get-FileHash cmdlet must re-read file to generate a SHA-256 digest for it.  This adds to the overall script execution time.

#>

# ---------------------------------------------------------[Initialisations]--------------------------------------------------------

# Set priority to reduce CPU usage
( [System.Diagnostics.Process]::GetCurrentProcess() ).PriorityClass = "Idle"

# Set Error Action to Silently Continue
$ErrorActionPreference = "SilentlyContinue"

# ----------------------------------------------------------[Declarations]----------------------------------------------------------

# Configuration parameters
$SrcDir = "D:\syslog\logs"											# Location of files to archive or delete
$DstDir = "D:\syslog\SyslogArchives\ISOtimestamp"					# Location of output archive files
$LogDir = "D:\syslog\logs"											# Location of output log file
$DistList = "C:\PowerShell\DistList.txt"								# Path and file name of the Distribution List for logs
$ArcAge = [int] 1													# Age (in days) of files to be archived (1 = yesterday and earlier)
$DelAge = [int] 10													# Age (in days) of files to be deleted
$NoDelete = [int] 0													# Deletion of files is disabled if this is not = 0

# Working variables
$Errors = [int] 0													# Count of parameter errors 

$StartTime = (Get-Date)												# Execution start time
$Today = $StartTime.toString("yyyy-MM-dd")							# Today's date in ISO format
$Now = $StartTime.toString("yyyy-MM-dd_HH-mm-ss")					# Date and time now in (almost) ISO format
$LogName = $($Now + ".log")											# Name of the log file for this run 
$LogFile = $([string](Join-Path -Path $LogDir -ChildPath $LogName))	# Path and name of the log file for this run
$Filter = "20??-??-??*"												# Only include files matching this pattern
$Files = ""															# List of candidate files in source directory

$ArcDate = (get-date).AddDays(-$ArcAge).toString("yyyy-MM-dd")		# Archive files < or = this date
$ArcCount = [int] 0													# Count of the number of files archived
$ArcTotal = [int] 0													# Count of the number of bytes in files archived
$DelDate = (get-date).AddDays(-$DelAge).toString("yyyy-MM-dd")		# Delete files < or = this date
$Delcount = [int] 0													# Count of the number of files deleted

$FileDate  = ""														# Date of current file
$PrevDate = ""														# Date of previous file
$ArcFlag = [int] 0													# We just archived this file

# Email parameters													# Set $EmailDist to "" to disable email log
$EmailServer = "mail.example.org"
$EmailFrom = $("Friendly Name <friendly.name@mail.example.org>")
$EmailTo = $([string[]] (get-content $DistList))						# Email log to email addresses in $DistList.
$EmailSubject = $($Today + " Syslog Archive/Delete Report")

# -----------------------------------------------------------[Check and Log Parameters]---------------------------------------------

# Test that the log directory exists.  If it doesn't, log an error to screen.
If (-not (Test-Path -Path $LogDir))
	{
	Write-Host $("Specified log path " + $LogDir + " does not exist!!!!!!!!!")
	Exit
	}

# Open the log file
	New-Item -Path $LogFile
# Write banner
	Add-Content -Path $LogFile $("***************************************************************************************************")
	Add-Content -Path $LogFile $("Started processing at: $Now")
	Add-Content -Path $LogFile $("***************************************************************************************************")
	
# Write to screen for debug mode
	Write-Debug "***************************************************************************************************"
	Write-Debug "Started processing at: + $Now" 
	Write-Debug "***************************************************************************************************"
 
# Test all other parameters and exit if there are any errors
If (-not (Test-Path -Path $SrcDir))
	{
	Add-Content -Path $LogFile $("ERROR: Source directory does not exist")
	Write-Host $("Specified source path " + $SrcDir + " does not exist!!!!!!!!!")
	$Errors = ($Errors + 1)
	}
If (-not (Test-Path -Path $DstDir))
	{
	Add-Content -Path $LogFile $("ERROR: Destination directory does not exist")
	Write-Host $("Specified destination path " + $DstDir + " does not exist!!!!!!!!!")
	$Errors = ($Errors + 1)
	}
If ($ArcAge -lt 1)
	{
	Add-Content -Path $LogFile $("ERROR: Archive age must be greater than or equal to 1")
	Write-Host $("ERROR: Archive age must be greater than or equal to 1")
	$Errors = ($Errors + 1)
	}
If (-not ($DelAge -gt $ArcAge))
	{
	Add-Content -Path $LogFile $("ERROR: Delete age must be greater than Archive age")
	Write-Host $("ERROR: Delete age must be greater than Archive age")
	$Errors = ($Errors + 1)
	}

# Close the log and exit if there were any errors
If ($Errors -gt 0)
	{
	Log-Finish -LogPath $LogFile
	Exit
	}

# Log the running parameters
Add-Content -Path $LogFile $("Source directory:      " + $SrcDir)
Add-Content -Path $LogFile $("Destination directory: " + $DstDir)
Add-Content -Path $LogFile $("Logging directory:     " + $LogDir)
Add-Content -Path $LogFile $("Archive Age (days):    " + $ArcAge)
Add-Content -Path $LogFile $("Deletion Age(days):    " + $DelAge)

# -------------------------------------------------------[Begin Processing]---------------------------------------------------------

# Find all objects in the source directory that match the filter, exclude sub-directories and sort file list by name 
$Files = Get-ChildItem -Path $SrcDir -Filter $Filter | where { !$_.PSIsContainer } | sort name

# ------------------------------------------------------[Begin Archival Pass]-------------------------------------------------------

Add-Content -Path $LogFile $("***************************************************************************************************")
Add-Content -Path $LogFile $("Archiving files dated " + $ArcDate + " and earlier.")
Add-Content -Path $LogFile $("***************************************************************************************************")

ForEach ($File in $Files)
	{
	$FileDate = $File.name.substring(0,10)
	if ($FileDate -ne $PrevDate)
		{
		$ArcFlag = 0
		if ($FileDate -le $ArcDate)
			{
			if (-not (Test-Path $($DstDir + "\" + $FileDate + ".zip")))
				{
				$ArcFlag = 1
				$CompressAll = "C:\PowerShell\7za.exe a -tzip $($DstDir + "\" + $FileDate) $($SrcDir + "\" + $FileDate + "*") -mx1"
				Invoke-Expression $CompressAll
				Add-Content -Path $LogFile $(" " )
				Add-Content -Path $LogFile $("Created " + $DstDir + "\" + $FileDate + ".zip")
				}
			}
		}
	if ($ArcFlag -eq 1)
		{
# 		$CompressOne = "C:\PowerShell\7za.exe a -tzip $($DstDir + "\" + $FileDate) $($SrcDir + "\" + $File.Name) -mx1"
# 		Invoke-Expression $CompressOne				
		Add-Content -Path $LogFile $("        Added " + $File.name)
		Add-Content -Path $LogFile $("              File size:      " + $("{0:N0}" -f $File.length))
		$LastWritten = $File.LastWriteTime.toString("yyyy-MM-dd HH:mm:ss")
		Add-Content -Path $LogFile $("              Last modified:  " + $LastWritten)
		$FileHash = get-filehash -path $($SrcDir + "\" + $File.name)
		Add-Content -Path $LogFile $("              SHA-256 digest: " + $FileHash.hash)
		$ArcTotal = $ArcTotal + $File.length
		$ArcCount = $ArcCount + 1
		}
	$PrevDate = $FileDate
	}
	
If ($ArcCount -eq 0)
	{
	Add-Content -Path $LogFile $(" " )
	Add-Content -Path $LogFile $("  No files to archive!")
	Add-Content -Path $LogFile $(" " )
	}
Else
	{
	Add-Content -Path $LogFile $(" " )
	Add-Content -Path $LogFile $("Archived " + $ArcCount + " files containing a total of " + $("{0:N0}" -f $ArcTotal) + " bytes")
	Add-Content -Path $LogFile $(" " )
	}
# ------------------------------------------------------[Begin Deletion Pass]--------------------------------------------------------

# Uses the same list of files obtained for the archival pass

$PrevDate = ""
 	
If ($NoDelete -eq 0)
	{
	Add-Content -Path $LogFile $("***************************************************************************************************")
	Add-Content -Path $LogFile $("Deleting files dated " + $DelDate + " and earlier.")
	Add-Content -Path $LogFile $("***************************************************************************************************")

	ForEach ($File in $Files)
		{
		$FileDate = $File.name.substring(0,10)
		if ($FileDate -le $DelDate)
			{
			if (Test-Path $($DstDir + "\" + $FileDate + ".zip"))
				{
				if ($FileDate -ne $PrevDate)
					{
					Add-Content -Path $LogFile $(" " )
					Add-Content -Path $LogFile $("Deleting files from " + $FileDate)
					}
				Remove-Item $($SrcDir + "\" + $File.name)
				Add-Content -Path $LogFile $("   Deleted " + $File.name)
				$DelCount = $DelCount + 1
				}			
			else
				{
				Add-Content -Path $LogFile $("   No archive found for " + $FileDate + ". Not deleting " + $File.name)
				}
			}
		$PrevDate = $FileDate	
		}
	}
Else
	{
	Add-Content -Path $LogFile $("***************************************************************************************************")
	Add-Content -Path $LogFile $("Deletion of aged files is disabled!")
	Add-Content -Path $LogFile $("***************************************************************************************************")
	}
	
If ($DelCount -eq 0)
	{
	Add-Content -Path $LogFile $(" " )
	Add-Content -Path $LogFile $("  No files to delete!")
	Add-Content -Path $LogFile $(" " )
	}
Else
	{
	Add-Content -Path $LogFile $(" " )
	Add-Content -Path $LogFile $("Deleted a total of " + $DelCount + " files.")
	Add-Content -Path $LogFile $(" " )
	}

# ------------------------------------------------------[End Log File]--------------------------------------------------------------
$EndTime = (Get-Date)
$Elapsed = New-TimeSpan -Start $StartTime -End $EndTime
$Now = $EndTime.toString("yyyy-MM-dd HH-mm-ss")

Add-Content -Path $LogFile $("*************************************************************************************************")
Add-Content -Path $LogFile $("Approximate run time (HH:MM:SS):   {0:hh}:{0:mm}:{0:ss}" -f $Elapsed) 
Add-Content -Path $LogFile $("*********************************************************************************** End of report")
  
# Write to screen for debug mode
Write-Debug ""
Write-Debug "***************************************************************************************************"
Write-Debug "Finished processing at: $Now" 
Write-Debug "***************************************************************************************************"

# ------------------------------------------------------[Email Log File]------------------------------------------------------------

$EmailBody = "$(cat $LogFile|out-string)"
Send-Mailmessage -from $EmailFrom -to $EmailTo -subject $EmailSubject -body $EmailBody -smtpServer $EmailServer

# ------------------------------------------------------[End Processing]------------------------------------------------------------

Exit

