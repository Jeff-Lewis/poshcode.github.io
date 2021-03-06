$oldserver = "hostname"
# Exclude the following shares. Update to particular needs of your environment.
$excludes = @("DLOAgent","faxclient","CertEnroll","Resources$","FxsSrvCp$","tsweb","NETLOGON","WSUSTemp","prnproc$","SYSVOL","Address","tsclient","WsusContent","UpdateServicesPackages","print$")
$shares = get-wmiobject -computername $oldserver -Class win32_share|where-object {($_.type -eq 0) -and ($excludes -notcontains $_.name)}

foreach ($share in $shares)
 {
 #  This section was required as the old server had a C: and a D:
 #  The new server had only a C: so had to edit the paths to replace any reference of D: with C:
 	if ($share.path -like "D:*")
 	    {
		$newntfspath = $share.path.replace("D:\","C:\")
		Write-Host -foregroundcolor Green "Destination folder" $newntfspath
		}
	else {  $newntfspath = $share.path
		Write-Host -foregroundcolor Green "Destination folder" $newntfspath
		}

#       Test to see if the file paths already exist - only needed on the first run if you intend to robocopy more than once.

	    if (!(Test-Path $newntfspath))
		{
		Write-Host -foregroundcolor Green "Folder $newntfspath does not exist"
		Write-Host -foregroundcolor Green "Starting robocopy job"
#       Robocopy job - requires that the log folder exists already - in this case C:\RobocopyLogs
		robocopy \\$oldserver\$($share.name) $newntfspath /W:5 /R:2 /XO /E /PURGE /SEC /V /NFL /LOG:C:\RobocopyLogs\$($share.name).txt
		}
	else { Write-Host -foregroundcolor Red "Folder $newntfspath Already exists"
		Write-Host -foregroundcolor Red "Skipping this folder"
		Write-Host -ForegroundColor Red "Creating error log"
		New-Item -force -ItemType File -Path C:\RobocopyLogs\$($share.name)_Fail.txt
		Set-content -Value "Location already exists, Robocopy was not attempted" -Path C:\RobocopyLogs\$($share.name)_Fail.txt
		}

        $sourceperms = get-wmiobject -computername $oldserver -Class win32_LogicalShareSecuritySetting | Where-Object {$_.name -eq $share.name}
        $sourceperms = $sourceperms.GetSecurityDescriptor().Descriptor

#       FOR TESTING ONLY -- Drilling into the source permissions object to display friendly name and accessrights values
#	    $sourceperms = $sourceperms.DACL
#	    foreach ($DACL in $sourceperms)
#		    {
#		    $DACLname = $DACL.trustee.name
#		    $DACLname
#		    $Accessrights = $($DACL.Accessmask -as [Security.AccessControl.FileSystemRights])
#		    $Accessrights
#		    }

        if (!(get-wmiobject -Class Win32_Share |Where-Object {$_.name -eq $share.name}))
            {
            Write-Host -ForegroundColor Green "Creating shared folder"
#           Creates an object with the Win32_share class
            $newshare = [wmiclass]"Win32_Share"
#           Creates the share using the "create" method of the wmiclass object.
#           This take 7 arguments in a specific order 1.Path 2.Share Name 3.Type (0 is for file share) 4. Max connections allow 5. Description 6. Password 7.Permissions object 
            $newshare = $newshare.Create($newntfspath,$share.name,0,$null,$null,$null,$sourceperms)
		    }
        else { Write-Host -foregroundcolor RED "Shared folder already exists"
             }
 }
