################################################################
#																
# PC Info v1.0 for SNOS(http://www.snos.ru/)
# (c)2009 by MakcoH(http://twitter.com/MakcoH)
# Script gathers information about remote PC using SCCM and WMI
#
################################################################

# Get the path to Program Files and IE to load SCCM report that shows 
# PC name by User name
$pr = [system.environment]::GetFolderPath("ProgramFiles")
$ie = $pr + "\Internet Explorer\iexplore.exe"
$ie = '"' + $ie + '"' + " https://sccm/SMSReporting/Reports.asp?ReportId=423"
Invoke-Command -ScriptBlock {cmd /c $ie}

# File information saves on the Desktop
$pr = [system.environment]::GetFolderPath("Desktop")
$o = $pr + "\info.txt"

# Get the PC Name and input it
$comp = read-host "Input PC Name for gathering information: "

# Let's ping it to know that it's alive :)
$tt = "ping $comp"
$ping = Invoke-Command -ScriptBlock {cmd /c $tt}
if($ping -match "Answer*"){					# Maybe string "Answer*" is incorrect. I use Russian version of Windows :) 

# this line is for separating blocks of different pc information
$t = "-" * 25

# WMI Classes for getting right information
$cInfo = Get-WmiObject win32_ComputerSystem -computername $comp
$OSInfo = Get-WmiObject win32_OperatingSystem -computername $comp
$ServInfo = Get-WmiObject win32_Service -computername $comp
$DiskInfo = Get-WmiObject Win32_LogicalDisk -computername $comp

## -----------------------------------------------------------------------

$t | Out-File $o

out-file -InputObject "PC Information [ $(Get-Date) ]" -FilePath $o -Append
$t | Out-File $o -Append

out-file -InputObject "PC name: $($cInfo.Name)" -FilePath $o -Append
# out-file -InputObject "PC IP: $($ipInfo.IPAddress[0])" -FilePath $o -Append

# Gets information from command ping. Also may be incorrect because of localization
out-file -InputObject "PC IP: $($ping[7]) $($ping[9])" -FilePath $o -Append

$t | Out-File $o -Append
out-file -InputObject "Username: $($OSInfo.RegisteredUser)" -FilePath $o -Append
out-file -InputObject "Domain: $($cInfo.Domain)" -FilePath $o -Append
out-file -InputObject "PC model: $($cInfo.Manufacturer) $($cInfo.Model)" -FilePath $o -Append

out-file -InputObject "OS Version: $($OSInfo.caption) $($OSInfo.CSDVersion)" -FilePath $o -Append
$mem = $cInfo.TotalPhysicalMemory / (1024 *1024)
$t | Out-File $o -Append
out-file -InputObject "RAM: $mem Mb" -FilePath $o -Append
out-file -InputObject "" -FilePath $o -Append
out-file -InputObject "Logical disks: " -FilePath $o -Append
$DiskInfo | foreach { Out-File -InputObject "On $($_.DeviceID)($($_.FileSystem)) is free $($($_.FreeSpace)/(1024*1024)) Mb" -FilePath $o -Append}

$t | Out-File $o -Append
out-file -InputObject "Printers:" -FilePath $o -Append
Get-WmiObject Win32_Printer | foreach{ 
if($_.Default -eq $true){
 $cap = $_.caption + "(default)"
 if($_.network -eq $true){$cap = $cap + "(network)"}
 Out-File -InputObject ($cap) -FilePath $o -Append
 } else { 
  $cap = $_.caption
  if($_.network -eq $true){$cap = $cap + "(network)"}
  Out-File -InputObject $cap -FilePath $o -Append
  }
}
$t | Out-File $o -Append
out-file -InputObject "Applications:" -FilePath $o -Append
out-file -InputObject "Internet Explorer Version: $((([wmiclass]"\root\default:stdRegProv").GetStringValue(2147483650,"SOFTWARE\Microsoft\Internet Explorer\","Version")).sValue)" -FilePath $o -Append

# Get Antivirus Information
$AntiVirusExist = 0
$ServInfo | foreach {
 if($_.Description -like "*Eset*"){
  $AntiVirusExist = 1
  $cap = "Service Nod32: $($_.Name)"
  if($_.state -eq "Running"){ $cap = $cap + "(running)"}
  out-file -InputObject $cap -FilePath $o -Append
 }
 
 if($_.Description -like "*Avast*"){
  $AntiVirusExist = 1
  $cap = "Service Avast: $($_.Name)"
  if($_.state -eq "Running"){ $cap = $cap + "(running)"}
  out-file -InputObject $cap -FilePath $o -Append
 }
 
 if($_.Description -like "*Forefront*"){
  $AntiVirusExist = 1
  $cap = "Service Forefront: $($_.Name)"
  if($_.state -eq "Running"){ $cap = $cap + "(running)"}
  out-file -InputObject $cap -FilePath $o -Append
 }
}

if($AntiVirusExist -eq 0){
 out-file -InputObject "Antivirus not detected. Check services:" -FilePath $o -Append
 $t | Out-File $o -Append
 $servinfo | ft name,startmode,state,status | Out-File $o -Append
 $t | Out-File $o -Append
 }
}

# if ping isn't successful then input all ping information to file 
else
{
 $ping | Out-File $o
}
# open this file with notepad
notepad $o
