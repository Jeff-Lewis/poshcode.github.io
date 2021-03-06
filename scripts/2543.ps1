function Group-ByObject {
#.Synopsis
# Groups by a set of properties, returning objects
#.Description
# A wrapper for the built-in Group-Object cmdlet which returns one of the original objects (with separate properties for each property used to group) rather than a simple string representation as the "name" of the group. Optionally adds _count and _details properties which are the original Count and Group properties returned from group-object
#.Example
# Get-Process svchost | Group-ByObject Name, BasePriority -Count
#
# Groups Service Hosts by their BasePriority
#
#.Parameter InputObject
# The input objects are the items to be grouped
#.Parameter Property
# One or more properties to group on
#.Parameter Details
# One or more properties to collect as an array on the output
#.Parameters Group
# If set, forces all of the grouped items to be included in the _group property
#.Parameters Count
# If set, shows a count of all the grouped items on each group as the _count property
[CmdletBinding()]
param(
  [Parameter(ValueFromPipeline=$true,Mandatory=$true)]
  $InputObject
, 
  [Parameter(Position=0)]
  [object[]]$Property
, 
  [Parameter(Position=1)]
  [object[]]$Details
, 
  [Alias("All","SD")]
  [switch]$Group
, 
  [switch]$Count
)
begin { 
  $InputItems = @() 
  $select = $property
  if ($Count){ $select += @{ n="_count"; e={$group.count} } }
  if ($Details){ foreach($d in $details) { $select += @{ n="$d"; e={$group.group | Select -Expand "$d"} } } }
  if ($Group){ $select += @{ n="_group"; e={$group.group} } }
}
process { $InputItems += $InputObject }
end {
  foreach($group in $InputItems | Group-Object $property) { 
    $group.Group[0] | Select-Object $select 
  }
}
}

set-alias groupby group-byobject
set-alias grby group-byobject
