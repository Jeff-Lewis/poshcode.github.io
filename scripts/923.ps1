#  Glenn Sizemore ~ www . Get-Admin . Com
#  Example Powershell function to get the NFS Exports from a NetApp Filer
#  First you'll need to download the OnTap SDK 3.5 : http://communities.netapp.com/docs/DOC-1365
#  within the download your interested in .\manage-ontap-sdk-3.5\lib\DotNet\ManageOntap.dll
#  Next load the library... 
#  $Path = 'C:\Users\glnsize\Downloads\manage-ontap-sdk-3.5\lib\DotNet\ManageOntap.dll'
#  [Reflection.Assembly]::LoadFile($Path)
#
#  Almost there next step create a NaServer connection object
#  Here we are connecting to the NetApp Filer TOASTER1, and setting the api to V1.8
#  $NaServer = New-Object NetApp.Manage.NaServer("TOASTER1",1,8)
#  Call the setAdminUser Method and supply some credentials
#  $NaServer.SetAdminUser('root', 'password')
#
#  Now we're ready to go simply call the function passing your NAServer object as a parameter.
#  Get-NaNfsExport -Server $NaServer 
#
#  Get-NaNfsExport -Server $NaServer -Path /vol/vol0

Function Get-NaNfsExport {
    Param(
        [NetApp.Manage.NaServer]
        $Server,
        [String]
        $Path
    )
    Begin {
        $out = @()
    }
    Process {
        trap [NetApp.Manage.NaAuthException] {
            # Example trap to catch bad credentials
            Write-Error "Bad login/password".
            break
        }
        #generate a new naelement request
        $NaOut = New-Object NetApp.Manage.NaElement("nfs-exportfs-list-rules")
              
        # $NaServer.InvokeElem($NaOut) -> retrieve the results of the $NaOut request
        # ..($NaOut).GetChildByName("rules") -> select the rules element from results
        # ..GetChildByName("rules").getchildren() -> get any child elements under rules.
        $NaResults = $Server.InvokeElem($NaOut).GetChildByName("rules").getchildren()    
        
        #ForEach NFS Rule returned, serialize the output into a PSObject.
        foreach ($NaElement in $NaResults) {
            $NaNFS = "" | Select-Object Path, ActualPath, ReadOnly, ReadWrite, Root, Security
            $NaNFS.Path = $NaElement.GetChildContent("pathname")
            
            # This is where the OnTap SDK can get a little nuts... 
            # if you perfer XML then simply try $NaElement.ToPrettyString('')
            switch ($NaElement) {
                # if Read-Only is present
                {$_.GetChildByName("read-only")}
                	{	
                        # Get all child elements
                		$ReadOnly = ($_.GetChildByName("read-only")).getchildren()
                        #Foreach elm in read-only
                		foreach ($read in $ReadOnly) {
                            # [bool] if exists "all-hosts"
                			If ($read.GetChildContent("all-hosts")) {
                				$roList = 'All-Hosts'
                			}
                            # Else get the name of the export!
                			Elseif ($read.GetChildContent("name")) {
                				$roList += $read.GetChildContent("name")
                			}
                		}
                        # add our new list to the output
                		$NaNFS.ReadOnly = $roList
                	}
                # if Read-write is present
                {$_.GetChildByName("read-write")}
                	{	
                        $ReadWrite = ($_.GetChildByName("read-write")).getchildren()
                		foreach ($write in $ReadWrite) {
                			If ($write.GetChildContent("all-hosts")) {
                				$rwList = 'All-Hosts'
                			}
                			Elseif ($r.GetChildContent("name")) {
                				$rwList += $write.GetChildContent("name")
                			}
                		}
                		$NaNFS.ReadWrite = $rwList
                	}
                # if root is present
                {$_.GetChildByName("root")}
                	{
                		$Root = ($_.GetChildByName("root")).getchildren()
                		foreach ($r in $Root) {
                			If ($r.GetChildContent("all-hosts")) {
                				$rrList = 'All-Hosts'
                			}
                			Elseif ($r.GetChildContent("name")) {
                				$rrList += $r.GetChildContent("name")
                			}
                		}
                		$NaNFS.Root = $rrList
                	}
                {$_.GetChildByName("sec-flavor")}
                	{
                		$Security = ($_.GetChildByName("sec-flavor")).getchildren()
                		foreach ($s in $Security) {
                			if ($r.GetChildContent("flavor")) {
                				$SecList += $r.GetChildContent("flavor")
                			}
                		}
                		$NaNFS.Security = $SecList
                	}
                {$_.GetChildByName("actual-pathname")}
                    {
                    
                    	$NaNFS.ActualPath = $_.GetChildByName("actual-pathname")
                    }
                # needed for mixed vol reporting...
                {!$_.GetChildByName("actual-pathname")}
                    {
                    
                    	$NaNFS.ActualPath = $_.GetChildContent("pathname")
                    }
            }
            $out += $NaNFS
        }
    }
    End {
        If ($Path) {
            return $out | ?{$_.Path -match $Patch}
        } 
        else {
            return $out
        }
    }
}
