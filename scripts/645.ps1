# Author: Hal Rottenberg
# Purpose: Find matching members in a local group
# Used tip from RichS here: http://powershellcommunity.org/Forums/tabid/54/view/topic/postid/1528/Default.aspx

# Change these two to suit your needs
$ChildGroups = "Domain Admins", "Group Two"
$LocalGroup = "Administrators"

$MemberNames = @()
# uncomment this line to grab list of computers from a file
# $Servers = Get-Content serverlist.txt
$Servers = $env:computername # for testing on local computer
foreach ( $Server in $Servers ) {
@@# Put $MemberNames = @() here to clear out the MemberNames variable between servers, otherwise we start to get incorrect results
@@        $MemberNames = @()
	$Group= [ADSI]"WinNT://$Server/$LocalGroup,group"
	$Members = @($Group.psbase.Invoke("Members"))
	$Members | ForEach-Object {
		$MemberNames += $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)
	} 
	$ChildGroups | ForEach-Object {
		$output = "" | Select-Object Server, Group, InLocalAdmin
		$output.Server = $Server
		$output.Group = $_
		$output.InLocalAdmin = $MemberNames -contains $_
		Write-Output $output
	}
}
