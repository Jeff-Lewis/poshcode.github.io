$Data = @()

Function writeHtmlHeader
{
param($title, $fileName)
$date = ( Get-Date ).ToString('dddd dd/MM/yyyy')
$head = @"
<html>
<head>
<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>
<title>$title</title>
<STYLE TYPE="text/css">
<!--
td {
font-family: Tahoma;
font-size: 11px;
border-top: 1px solid #999999;
border-right: 1px solid #999999;
border-bottom: 1px solid #999999;
border-left: 1px solid #999999;
padding-top: 0px;
padding-right: 0px;
padding-bottom: 0px;
padding-left: 0px;
}
body {
margin-left: 5px;
margin-top: 5px;
margin-right: 0px;
margin-bottom: 10px;
table {
border: thin solid #000000;
}
-->
</style>
</head>
<body>
<table width='800'>
<tr bgcolor='#808080'>
<td colspan='1' height='25' align='center'>
<font face='tahoma' color='#D5E14D' size='4'><strong>$title - $date</strong></font>
</td>
</tr>
</table>
"@
$head | Out-File $fileName
}

# ==============================================================================================
Function writeTableHeader
{
param($fileName)
$tableHeader = @"
<table width='800'><tbody>
<tr bgcolor=#E5E5E5>
<td width=10% align='center'>Time</td>
<td width=20% align='center'>Event Type</td>
<td width=10% align='center'>Severity </td>
<td width=20% align='center'>Username</td>
<td width=40% align='center'>Text</td>
</tr>
"@
$tableHeader | Out-File $fileName -append
}

# ==============================================================================================
Function writeData
{
                param([string[]]$infoColumns, [string[]]$rowData, $fileName)
                
                # Populate info cells
                $tableEntry = "<tr>"
                $infoColumns | % {
                #                $tableEntry += "<td>$_</td>"
                }
                
                # Populate data cells 
                $rowData | % {                              
					$tableEntry += "<td bgcolor='#E4E4E4' align=center><font color='#F6921E'><strong>$_</strong></font></td>" }
                $tableEntry += "</tr>"
                $tableEntry | Out-File $fileName -append
}

# ==============================================================================================
Function writeHtmlFooter
{
param($fileName)
@"
</body>
</html>
"@ | Out-File $FileName -append
}

#Start of View Code---------------------------------------------------------------------
add-PSSnapin vmware.view.broker
# Define credentials to connect to the View Connection Server.
$username = "username"
$password = "password"
$domain = "domain"
$VCS = "view connection server address"

$CurrentDate = Get-Date
$DateSelection = ($CurrentDate).addhours(-1)
$exportfile = 'c:\pathtoexportfile.html'
$AllEvents = Get-EventReport -ViewName config_changes -StartDate $DateSelection | select time,eventtype,severity,userdisplayname,moduleandeventtext

If ($AllEvents -ne $null) {
writeHtmlHeader "VDI Configuration Change Report" $ExportFile
writeTableHeader $ExportFile
$Allevents | % { writedata -fileName $exportfile -rowData $_.time,$_.eventtype,$_.severity,$_.userdisplayname,$_.moduleandeventtext }
writeHtmlFooter $ExportFile

$smtpServer = "smtp.yourserver.com"
$msg = new-object Net.Mail.MailMessage
$smtp = new-object Net.Mail.SmtpClient($smtpServer)
$msg.From = "VDIConfigChecker@something.com"
$msg.To.Add("youremailhere@company.com")
$msg.IsBodyHtml = $true
$msg.Subject = "VDI Configuration Change Notification"
$msg.Body = (gc $exportfile)
$smtp.Send($msg)
}
Remove-Item $exportfile

