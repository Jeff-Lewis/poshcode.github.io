Add-Type @'
public class MyAccounts
{
    public System.Collections.ArrayList localusers; 
    public System.Collections.ArrayList domainusers;
    public System.Collections.ArrayList domaingroups;
}
'@   

function get-localadministrators {
    param ([string]$computername=$env:computername)

    $computername = $computername.toupper()
    
                Add-Type -AssemblyName System.DirectoryServices.AccountManagement
                $PrincipalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Machine, $computername)
                           
                $GroupPrincipal = New-Object System.DirectoryServices.AccountManagement.GroupPrincipal($PrincipalContext)
                $Searcher = New-Object System.DirectoryServices.AccountManagement.PrincipalSearcher
                $Searcher.QueryFilter = $GroupPrincipal
                $localadmins = $Searcher.FindAll() | where {$_.Sid -eq 'S-1-5-32-544'} # Administrators group
                
                #StructuralObjectClass=user
                #StructuralObjectClass=group
                #ContextType = Domain
                #ContextType = Machine
                                
                $localusers = New-Object System.Collections.ArrayList
                $domainusers = New-Object System.Collections.ArrayList
                $domaingroups = New-Object System.Collections.ArrayList
                
                $objOutput= New-Object MyAccounts
                
                
                
                foreach ($ladmin in $localadmins.Members)
                {
                  if ($ladmin.ContextType -eq 'Machine')
                  {
                   [void] $localusers.Add($ladmin)
                  }                                 
                  if ($ladmin.ContextType -eq 'Domain')
                  {
                           
                    if ($ladmin.StructuralObjectClass -eq 'user') {
                      [void] $domainusers.Add($ladmin)

                    }                  
                    if ($ladmin.StructuralObjectClass -eq 'group') {
                      [void] $domaingroups.Add($ladmin)
                    }
                  }                                        
                }    
                
                $objOutput.localusers=$localusers
                $objOutput.domainusers=$domainusers
                $objOutput.domaingroups=$domaingroups
                
                    
    return $objoutput
}#end function
