###
# Purpose        : Import vCenter roles and permissions into a new vCenter.
# Created        : 18/08/2010
# Author         : VMware Community, namely Alan Renouf and Luc Dekens
# Pre-requisites : Source file vcenter-permissions.xml
###

# Parameters
$VC1 = "new vCenter"

# Functions
function New-Role
{
    param($name, $privIds)
    Begin{}
    Process{

        $roleId = $authMgr.AddAuthorizationRole($name,$privIds)
    }
    End{
        return $roleId
    }
}

function Set-Permission
{
param(
[VMware.Vim.ManagedEntity]$object,
[VMware.Vim.Permission]$permission
)
Begin{}
Process{
    $perms = $authMgr.SetEntityPermissions($object.MoRef,@($permission))
}
End{
    return
}
}

# Connect to vCenter server
Connect-VIServer "$VC1"

# Main
# Create hash table with the current roles
$authMgr = Get-View AuthorizationManager
$roleHash = @{}
$authMgr.RoleList | % {
    $roleHash[$_.Name] = $_.RoleId
}

# Read XML file
$XMLfile = "d:\documents\vcenter-permissions.xml"
$vInventory = [xml]"<dummy/>"
$vInventory.Load($XMLfile)

# Define Xpaths for the roles and the permissions
$XpathRoles = "Inventory/Roles/Role"
$XpathPermissions = "Inventory/Permissions/Permission"

# Create custom roles
$vInventory.SelectNodes($XpathRoles) | % {
    if(-not $roleHash.ContainsKey($_.Name)){
        $privArray = @()
        $_.Privilege | % {
            $privArray += $_.Name
        }
        $roleHash[$_.Name] = (New-Role $_.Name $privArray)
    }
}

# Set permissions
$vInventory.SelectNodes($XpathPermissions) | % {
    $perm = New-Object VMware.Vim.Permission
    $perm.group = &{if ($_.Group -eq "true") {$true} else {$false}}
    $perm.principal = $_.Principal
    $perm.propagate = &{if($_.Propagate -eq "true") {$true} else {$false}}
    $perm.roleId = $roleHash[$_.Role]

    $EntityName = $_.Entity.Replace("(","\(").Replace(")","\)")
    $EntityName = $EntityName.Replace("[","\[").Replace("]","\]")
    $EntityName = $EntityName.Replace("{","\{").Replace("}","\}")

    $entity = Get-View -ViewType $_.EntityType -Filter @{"Name"=("^" + $EntityName + "$")}
    Set-Permission $entity $perm
}

# Disconnect from vCenter server
Disconnect-VIServer -server "$VC1" -Force -Confirm:$false
