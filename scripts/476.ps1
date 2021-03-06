 Get-VIServer YOURSERVER

$Excel = New-Object -Com Excel.Application
$Excel.visible = $True
$Excel = $Excel.Workbooks.Add()
$Addsheet = $Excel.sheets.Add()
$Sheet = $Excel.WorkSheets.Item(1)
$Sheet.Cells.Item(1,1) = "Name"
$Sheet.Cells.Item(1,2) = "Power State"
$Sheet.Cells.Item(1,3) = "Description"
$Sheet.Cells.Item(1,4) = "Number of CPUs"
$Sheet.Cells.Item(1,5) = "Memory (MB)"

$WorkBook = $Sheet.UsedRange
$WorkBook.Font.Bold = $True

$intRow = 2
$colItems = Get-VM | Select-Object -property "Name","PowerState","Description","NumCPU","MemoryMB" 

foreach ($objItem in $colItems) 
{
    $Sheet.Cells.Item($intRow,1) = $objItem.Name
			
    $powerstate = $objItem.PowerState
    If ($PowerState -eq 1) {$power = "Powerd On"}
    Else {$power = "Powerd Off"}
		
    $Sheet.Cells.Item($intRow,2) = $power
    $Sheet.Cells.Item($intRow,3) = $objItem.Description
    $Sheet.Cells.Item($intRow,4) = $objItem.NumCPU
    $Sheet.Cells.Item($intRow,5) = $objItem.MemoryMB
    
    $intRow = $intRow + 1

}

$WorkBook.EntireColumn.AutoFit()

$Sheet = $Excel.WorkSheets.Item(2)
$Sheet.Cells.Item(1,1) = "Name"
$Sheet.Cells.Item(1,2) = "Free Space"
$Sheet.Cells.Item(1,3) = "Capacity"

$WorkBook = $Sheet.UsedRange
$WorkBook.Font.Bold = $True

$intRow = 2
$colItems = Get-Datastore | Select-Object -property "Name","FreeSpaceMB","CapacityMB"

foreach ($objItem in $colItems) 
{
    $Sheet.Cells.Item($intRow,1) = $objItem.Name
    $Sheet.Cells.Item($intRow,2) = $objItem.FreeSpaceMB
    $Sheet.Cells.Item($intRow,3) = $objItem.CapacityMB
    
    $intRow = $intRow + 1

}

$WorkBook.EntireColumn.AutoFit()


$Sheet = $Excel.WorkSheets.Item(3)
$Sheet.Cells.Item(1,1) = "Name"
$Sheet.Cells.Item(1,2) = "State"

$WorkBook = $Sheet.UsedRange
$WorkBook.Font.Bold = $True

$intRow = 2
$colItems = Get-VMhost | Select-Object -property "Name","State" 

foreach ($objItem in $colItems) 
{
    $Sheet.Cells.Item($intRow,1) = $objItem.Name		
	
    $state = $objItem.State
    If ($state -eq 0) {$status = "Connected"}
    Else {$status = "Disconnected"}
		
    $Sheet.Cells.Item($intRow,2) = $status

    $intRow = $intRow + 1

}

$WorkBook.EntireColumn.AutoFit()
