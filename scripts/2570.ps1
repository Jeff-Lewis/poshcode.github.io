

function where-property([string] $PropertyName,[string]$SubProperty , $is,$isnot,$contains,$in)  
{
 process {
    if ($is) 
        {
           if ($_.$Propertyname -eq $is) { , $_ }
        }
    elseif ($isnot) 
        {  
            if ($_.$Propertyname -ne $is) { , $_ } 
        }
    elseif($contains)
        { 
                if ($subproperty)
                {
                    foreach ($prop in  $_.$propertyname )
                    {
                      if ($prop)
                       {
                         $subpropertyvalue = $prop.$subproperty
                         if ($subpropertyvalue -contains $contains ) { , $_ } 
                       }
                    }
                }
                else 
                {  
                    if ($_.$Propertyname -contains $contains) { , $_ }            
                }
            
        }
    elseif($in)
        { 
            if ($in -contains $_.$Propertyname) { , $_ }
        }    
     
    
 }
}
#set-alias and-property where-property


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
 
 
