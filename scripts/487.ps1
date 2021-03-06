#Revision 1 
#7-29-2008
#author Jon Owings
#contact - jowings at securas dot com
#
#Create a snapshot of all the vm's in a folder, 
#be sure to change to match your enviroment. use at your own risk, snapshots have been known to 
#cause certain configurations to lock (freeze) so test in a dev enviroment first.
#

$vCenter = VirtualCenterServer
$vFolder = VirtualCenterFolder
$sName = SnapshotName


Get-vc -server $vCenter
#remove old snapshots with the same name
Get-Folder $vFolder | get-vm | Get-Snapshot -Name $sName | Remove-Snapshot -Confirm:$false
#create a snapshot of each vm in that folder
Get-Folder $vFolder | get-vm | new-snapshot -Name $sName | ConvertTo-Html | Out-File create.htm

$smtpclient = New-Object System.Net.Mail.SmtpClient
$smtpclient.host = "mailserver.foo.bar"
$msg = New-Object system.Net.Mail.MailMessage
$att = New-Object System.Net.Mail.Attachment("create.htm")

$msg.Attachments.add($att)

$msg.From = "your@email.com"
$msg.to.add("your@email.com")
$msg.Subject = "Snapshot Backups"
$msg.Body = "This is the result of the snapshot scripts."

$smtpclient.send($msg)

Echo Done








