function Add-DGMembershipRule {

    param (

        $Identity,   #DN of the target, must be DN
        $RuleBase,   #Base DN for query
        $RuleFilter, #LDAP query
        $RuleType    #Include by Query, Explicit, etc... (1,2,3)
    )

    # Lookup the target group and return properties
    $convertGroup = Get-QADGroup $Identity

    # Extract the distinguishedName of the object for EDMS:// binding
    $strGroupDN   = $convertGroup.DN

    # Must use ADSI syntax in order to get access to Group 'MembershipRuleCollection' collection
    $objGroup     = $null
    $objGroup     = [ADSI] "EDMS://$strGroupDN"

    $objRuleCollection = $objGroup.MembershipRuleCollection

    # Build the new rule
    $rule         = New-Object -ComObject "EDSIManagedUnitCondition"
    $rule.Base    = "EDMS://$RuleBase"
    $rule.Filter  = $RuleFilter
    $rule.Type    = $RuleType

    # Add the new rule to the collection
    $objRuleCollection.Add($rule)

    # Commit changes to the directory object
    $objGroup.SetInfo()

<#
.SYNOPSIS
   
.DESCRIPTION
   Required:
   + Quest Active Roles cmdlets
   + Quest Active Roles Management Shell

   Rule _Type_ Codes:
   [1]  Include By Query
   [2]  Exclude By Query
   [3]  Include Explicitly
   [4]
   [5]
   [6]

.NOTES
   Author  : Vidrine
   Date    : 2014.04.11
   Contact : vidrine.dev@gmail.com

.PARAMETER Identity
   Specify the Identity of the target group.  Primarily, this will be the distinguishedName or
   sAMAccountName for the group object.

.PARAMETER RuleBase
   Specify the search base for the dynamic membership rule.

   If you are attempting to add an explicit user/group object, then use the CN for the user/group object.

   If you are adding a new LDAP query as a filter, use the CN for the OU you are targeting.
   >  DC=foo,DC=com

   *** "EDMS://" will be added automatically to the Base.  This prefix is needed for QARS.

.PARAMETER RuleFilter
   The LDAP filter for the dynamic membership rule.

.PARAMETER RuleType
   State the membership rule type, see below.  This determines the type of query built.

   Rule _Type_ Codes:
   [1]  Include By Query
   [2]  Exclude By Query
   [3]  Include Explicitly
   [4]
   [5]
   [6]

#>
}
