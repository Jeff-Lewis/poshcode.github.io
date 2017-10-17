﻿Function New-ISEScript
{
$strName = $env:username
$date = get-date -format d
$name = Read-Host "Filename"
if ($name -eq "") { $name="NewScriptTemplate_ISECommentBased" }
$synopsis = Read-Host "Synopsis"
if ($synopsis -eq "") { $synopsis="enter your synopsis of this script activity here" }
$description = Read-Host "Description"
if ($description -eq "") { $description="enter a brief description of this script here" }
$syntax = Read-Host "Syntax"
if ($syntax -eq "") { $syntax="enter syntax here" }
$email = Read-Host "eMail Address"
if ($email -eq "") { $email='myemail@mycompanyemail.com' }
$example1 = Read-Host "Example 1"
if ($example1 -eq "") { $example1="enter example 1 here" }
$example2 = Read-Host "Example 2"
if ($example2 -eq "") { $example2="enter example 2 here" }
$helpurl1 = Read-Host "enter the help url 1 here"
if ($helpurl1 -eq "") { $helpurl1="enter help url 1 here" }
$helpurl2 = Read-Host "enter the help url 2 here"
if ($helpurl2 -eq "") { $helpurl2="enter help url 2 here" }
$seealso1 = Read-Host "See Also 1"
if ($seealso1 -eq "") { $seealso1="enter see also 1 here" }
$seealso2 = Read-Host "See Also 2"
if ($seealso2 -eq "") { $seealso2="enter see also 2 here" }
$seealso3 = Read-Host "See Also 3"
if ($seealso3 -eq "") { $seealso3="enter see also 3 here" }
$comment=@();
while($s = (Read-Host "Comment").Trim()){$comment+="$s`r`n#"}
$file = New-Item -type file "$name.ps1" -force

$template=@"
<#
 .NAME
 	$name.ps1
 .SYNOPSIS
 	$synopsis
 .DESCRIPTION
 	$description
 .SYNTAX
 	$syntax
 .EXAMPLES
 	$example1
	$example2
 .NOTES
 	AUTHOR:	$strName
  	EMAIL:	$email
	DATE:	$date
  	COMMENT: $comment
 .HELPURL
 	$helpurl1
	$helpurl2
 .SEEALSO
 	$seealso1
	$seealso2
	$seealso3
#>

#region-----royalty and version info-----
###########################################################################
#
# You have a royalty-free right to use, modify, reproduce, and
# distribute this script file in any way you find useful, provided that
# you agree that the creator, owner above has no warranty, obligations,
# or liability for such use.
#
# VERSION HISTORY:
# 1.0 $date - Initial release
#
###########################################################################
#endregion-----royalty and version info-----

#region-----code begins here-------

#todo---enter your code here

#endregion-----code begins here-------
"@ | out-file $file
ii $file
}
 
Set-Alias new New-ISEScript
