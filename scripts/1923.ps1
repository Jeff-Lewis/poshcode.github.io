#Purpose:  		To remotely query select machines for system information	
#Author:  		Alex Smith
#Created:		6/11/2010
#Arguments:		IP Addresses or Hostnames of target PCs then path and file name
#Examples:		To query based on hostname or ip:   C:\>powershell .\WMIQuery.ps1 host1 
#				To print to a file:					C:\>powershell .\WMIQuery.ps1 host1 > file.txt
#########################################################################################################

##########Program Start##########
#Runs script for each argument given in commandline
foreach ($comp in $args)
{
echo ""
echo ""
echo ""
echo "System data for $comp "
echo ""
get-wmiObject win32_computerSystem -Computer $comp | format-table Manufacturer, Model -autosize #Manufacturer (Computer Manufacturer), Model (Computer Model)
get-wmiObject win32_operatingSystem -Computer $comp | format-table Name, OSArchitecture -autosize #Name (OS Name and Drive Intalled On), OSArchitecture (OS Architecture)
get-wmiObject win32_bios -Computer $comp | format-table SerialNumber -autosize #SerialNumber (Computer Serial Number)
get-wmiObject win32_processor -Computer $comp | format-table Name -autosize #Name (CPU Name, Model, Clockspeed)
get-wmiObject win32_operatingSystem -Computer $comp | format-table TotalVisibleMemorySize, FreePhysicalMemory -autosize #TotalVisibleMemorySize (Total memory), FreePhysicalMemory (Memory Available)
get-wmiObject win32_diskDrive -Computer $comp | format-table Model, InterfaceType, DeviceID, Partitions -autosize #Model (Device Model), InterfaceType (IDE, SCSI, Etc.), DeviceID (Divice ID #), Partitions (Number of Partitions on Disk)
get-wmiObject win32_volume -Computer $comp | format-table FileSystem, Label, DriveLetter, Capacity, FreeSpace -autosize #FileSystem (File System Type), Label (Drive Label), DriveLetter (C:, d:, Etc.), Capacity (Total Space), FreeSpace (Space Available)
get-wmiObject win32_operatingSystem -Computer $comp | format-table NumberOfUsers -autosize #NumberOfUsers (Total of Local User Accounts)
get-wmiObject win32_computerSystem -Computer $comp | format-table UserName -autosize #UserName (Hostname\Current User)
get-wmiObject win32_networkAdapterConfiguration -Computer $comp | format-table MACAddress, IPAddress, DefaultIPGateway -autosize #MacAddress (MAC Address), IPAddress (IP Address), DefaultIPGateway (Default Gateway)
}
