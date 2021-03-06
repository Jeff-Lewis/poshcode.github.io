function where-property([string] $PropertyName,[string]$SubProperty , $is,$isnot,$contains,$in,$SelectProperty)  
{

 process {
    $useprop = $SelectProperty
  Function _outobj {
    if ($useprop ) 
       {
        , $_.$useprop
       }
    else 
       {
        , $_
        }
    }
    if ($is) 
        {
           if ($_.$Propertyname -eq $is) { _outobj}
        }
    elseif ($isnot) 
        {  
            if ($_.$Propertyname -ne $is) { _outobj} 
        }
    elseif($contains)
        { 
                if ($subproperty)
                {
                    foreach ($prop in  $_.$propertyname )
                    {
                      if ($prop)
                       {                         
                         $foundmatch = $false
                         $subpropertyvalue = $prop.$subproperty
                         if ($subpropertyvalue -contains $contains ) { $foundmatch = $true }
                         if ($foundmatch) { _outobj } 
                       }
                    }
                }
                else 
                {  
                    if ($_.$Propertyname -contains $contains) { _outobj}            
                }
            
        }
    elseif($in)
        { 
             if ($subproperty)
                {
                    foreach ($prop in  $_.$propertyname )
                    {
                      if ($prop)
                       {                         
                         $foundmatch = $false        
                         #{  "RpcSs","AppID" -contains $_.servicesdependedon.name }                 
                         if ($in -contains $prop.$subproperty ) 
                            {
                             $foundmatch = $true 
                             }
                         if ($foundmatch) { _outobj } 
                       }
                    }
                }
                else 
                {  
                    if ($in -contains $_.$Propertyname ) { _outobj}            
                }
            #if ($in -contains $_.$Propertyname) { _outobj}
        }    
     
    
 }
}
set-alias ?. where-property
set-alias and. where-property
set-alias and-property where-property



#get-processes with a specific name
gps | where-property processname -is svchost
#get-processes all but a specific name
gps | where-property processname -isnot svchost
#get-processes with the processname in a specific list
gps | where-property processname -in iexplore,chrome
#get verbs in a specific group
get-verb | where-property group -in common


#get-commands that have a specific named parameter
 get-command | where-property parameters -subproperty keys  -contains Begin 
#and using an a lias to this for the and since it seems more HUMAN to say where X and Y, rather than Where x where y 
 get-command | where-property parameters -subproperty keys  -contains Name |  and-property commandtype -is alias

#get displayname of services that depend other services appid,rpcss
get-service | where-property ServicesDependedOn -SubProperty name -in AppID,rpcss | and-property status -is running -SelectProperty Displayname


