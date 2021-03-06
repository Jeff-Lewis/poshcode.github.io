#==========================================================================
# NAME: getunknownsids.ps1
#
# AUTHOR: Stephen Wheet
# Version: 4.0
# Date: 6/11/10
#
# COMMENT: 
#	This script was created to find unknown SIDs or old domain permissions
#   on folders.  It ignores folders where inheirtance is turned on.
#
#	This works on NETAPPS and WINDOWS servers.  You will need the DLL's
#
#   Version 2: completely changed the query method and ACL removal
#   Version 3: Added ability to query AD for servers, and handles getting
#              getting shares automatically from:
#	      NETAPP FILERS
#	      Windows servers
#   Version 4: Cleaned up folder checking and added checking for local
#              account checking so we could ignore.
#
#==========================================================================

Function checkshare {
   Param($PassedShareName)
   Process 
   {
            
            $path = "\\$serverFQDN\$PassedShareName"
            $filename = $path.Replace("\","-") + ".csv"


            #Place Headers on out-put file
            $list = "Task,Path,Access Entity,"
            $list | format-table | Out-File "c:\reports\unknownsids\$filename"

            #Populate Folders Array 
            Write-Host "Writing results to : $filename"
            $date = Get-Date
            Write-Host $date
            Write-Host "Getting Folders in:  $Path"
			#PSIscontainer means folders only
            [Array] $folders = Get-ChildItem -path $path -recurse | ? {$_.PSIsContainer} 


            #Process data in array
            ForEach ($folder in [Array] $folders)
            {
                #Check to see if there are any folders
				If ($folder.pspath){
					#Convert Powershell Provider Folder Path to standard folder path
					$PSPath = (Convert-Path $folder.pspath)
                	Write-Host "Checking Dir:  $PSPath"
    			
					#Check to make sure valid
					If ($PSPath){
						#Get the ACL's from each folder
						$error.clear()
                		$acl = Get-Acl -Path $PSPath
                		#Write log if no access
						if (!$?) {
                	    	$errmsg = "Error,$PSPath,ACCESS DENIED"
                	    	$errmsg | format-table | Out-File -append "$filename"
						} #end IF
    						
                		$ACL.Access |
						?{!$_.IsInherited} |
						?{ $_.IdentityReference -like $unknownsid -or $_.IdentityReference -like $olddomain } |
						% {$value = $_.IdentityReference.Value
                	
                	    	#Check for Local account
							$localsid = 0
							If ($value -like $unknownsid){
                        		$checkforlocal = $value.split("-")
                       	 		$total =$checkforlocal.count -1
                        		if ($checkforlocal[$total] -match "^100.$" -or $checkforlocal[$total] -match "^500"){
                         		   	$localsid = 1
									# You can uncomment the below if you want to report on local accounts.
								   	#$list = ("Local,$PSPath,$value")
									#$list | format-table | Out-File -append "$filename"
								}  #end IF
                    		}  #end IF
							
                    		If (!$localsid){
                                    Write-host "Found - $PSPath - $value"
									$list = ("Found,$PSPath,$value")
                          			$list | format-table | Out-File -append "$filename"
                            		
									#Remove Bad SID
                            		if ($removeacl) { $ACL.RemoveAccessRuleSpecific($_)
                                        Write-host "Deleting - $PSPath - $value"
                            	    	$list = ("Deleting,$PSPath,$value")
                            	    	$list | format-table | Out-File -append "$filename"
									}#end IF
                        
                            		if ($removeacl -and $value) {
                                        $date = Get-Date
                                        Write-Host $date
                                        Write-host "Setting - $PSPath"
                            	    	$list = ("Setting,$PSPath")
                             		   	$list | format-table | Out-File -append "$filename"
                                		Set-ACL $PSpath $ACL
                                		$value = ""
									} #end IF
                    		} #end if
                		} #end foreachobj
					} #end if
				} #end if	
            } #end ForEach 
	}#end Process
} #end function

get-pssnapin -registered | add-pssnapin -passthru
[void][Reflection.Assembly]::LoadFile('C:\reports\ManageOntap.dll') #Need this DLL from netapp 3.5SDK 
$ReqVersion = [version]"1.2.2.1254" 
$QadVersion = (Get-PSSnapin Quest.ActiveRoles.ADManagement).Version  #Need Quest plugins installed

if($QadVersion -lt $ReqVersion) { 
    throw "Quest AD cmdlets version '$ReqVersion' is required. Please download the latest version" 
} #end If

#Set variables
$value = ""
$unknownsid = "*S-1-5-21-*" #Broken SID Verify the Broken SID number on your system and replace
$olddomain = "Domain.local*" #Old w2k/nt4 domain
$ErrorActionPreference = "SilentlyContinue"
$removeacl = 0 #change to 1 if you want to remove the SID, 0 for only logging
$localsid = 0



#Get all the servers from the specified OU
$Servers = get-QADComputer -SearchRoot 'domain.local/ou/Server' # change the container.

Foreach ($server in $Servers ) {
	$serverFQDN = $server.dnsname
	write-host  $serverFQDN

	#Test ping server to make sure it's up before querying it
	$ping = new-object System.Net.NetworkInformation.Ping
	$Reply = $ping.Send($serverFQDN)
    if ($Reply.status -eq "Success"){
        Write-Host "Online"

		#Check for Netapp .. if found get the shares differently	   
        If ($serverFQDN -like "*netapp*"){
            $server = new-object netapp.manage.naserver($serverFQDN,1,0)
			
			#pass authentication
            $server.Style = "RPC"
			
			# Issue command to get the shares
            $NaElement = New-Object NetApp.Manage.NaElement("system-cli")
            $arg = New-Object NetApp.Manage.NaElement("args")
            $arg.AddNewChild('arg','cifs')
            $arg.AddNewChild('arg','shares')
            $NaElement.AddChildElement($arg)
            $CifsString = $server.InvokeElem($NaElement).GetChildContent("cli-output")
			
			# Split the returned txt up .. the $null makes it skip a line
            $null,$null,$Lines = $CifsString.Split("`n")

            Foreach ($line in $Lines ) {
                                
                # Had to trick it so skip the line with permissions, then exclude ETC$ adn c$
				if (!$line.startswith("			") -and $line -notlike "*Etc$*" -and $line -notlike "*C$*"){
                    $l= $line.Split(" ")
                    checkshare -PassedShareName $l[0] #Pass share to function
                } #end if
            } #end foreach
        } #end if
		
        Else{ #Else if a Windows server query via WMI
               
            Get-WMIObject Win32_Share -Computer $serverFQDN | 
            	where {$_.Name -like "*$*" -and $_.Name -notlike "*ADMIN*" -and $_.Name -notlike "*IPC*" -and $_.Name -notlike "*lib*"} |
				%{
              		#Set path 
            		$sharename = $_.name
            		checkshare -PassedShareName $sharename  #Pass share to function         
            	} #end ForEachObj
        } #End Else
    } #End If
} #end ForEach
