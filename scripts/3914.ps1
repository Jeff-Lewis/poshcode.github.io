$strComputer = "PrinterName"
$Ports = get-wmiobject -class "win32_tcpipprinterport" -namespace "root\CIMV2" -computername $strComputer
$Printers = get-wmiobject -class "Win32_Printer" -namespace "root\CIMV2" -computername $strComputer
$ports | Select-Object Name,Hostaddress | Set-Variable port
$Printers | Select-Object Name,PortName,DriverName,location,Description | Set-Variable print
$num = 0
$hash = @{}
do {
$hash.Add($port.name[$num], $port.hostaddress[$num])
$num = $num + 1
} until ($num -eq $ports.Count)

# Creates Table
$table = New-Object system.Data.DataTable “$PrinterInfo”
$colName = New-Object system.Data.DataColumn PrinterName,([string])
$colIP = New-Object system.Data.DataColumn IP,([string])
$colDrive = New-Object system.Data.DataColumn DriverName,([string])
$colLoc = New-Object system.Data.DataColumn location,([string])
$colDesc = New-Object system.Data.DataColumn Description,([string])
$table.columns.add($colName)
$table.columns.add($colIP)
$table.columns.add($colDrive)
$table.columns.add($colLoc)
$table.columns.add($colDesc)
$num = 0
Do {
$row = $table.NewRow()
$row.PrinterName = $printers.name[$num]
$row.IP = $hash.get_item($printers.PortName[$num])
$row.DriverName = $printers.drivername[$num]
$row.Location = $printers.Location[$num]
$row.Description = $printers.Description[$num]
$table.Rows.Add($row)
$num = $num + 1
} until ($num -eq $printers.Count)

$table | Select-Object PrinterName,IP,DriverName,Location,Description | Export-Csv C:\Printers.csv
