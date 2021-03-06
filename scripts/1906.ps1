param(
$Domen,
[string[]]$ObjectsDeleted
)

function Ping ($Name){ 
    $ping = new-object System.Net.NetworkInformation.Ping
    if ($ping.send($Name).Status -eq "Success") {$True}
    else {$False} 
	trap {Write-Verbose "Error Ping"; $False; continue}
}

[string[]]$ObjectPath
[string[]]$Disks
[string[]]$Info
[string[]]$Computers

$Computers = Get-QADComputer -Service $Domen -OSName '*XP*','*Vista*','*7*' -SizeLimit 0 -ErrorAction SilentlyContinue | 
			 Select-Object name -ExpandProperty name

foreach ($Computer in $Computers){
	$Alive = Ping $Computer
	if ($Alive -eq "True"){
		Write-Host "Seach $Computer" -BackgroundColor Blue
	
		trap {Write-Host "Error WmiObject $Computer";Continue}
		$Disks += Get-WmiObject win32_logicaldisk -ComputerName $Computer -ErrorAction SilentlyContinue | 
				Where-Object {$_.Size -ne $null}
		
		if ($Disks){
		
			foreach ($Disk in $Disks){
				
				if ($Disk.Name -like "*:*") {
					$Disk = $Disk.Name.Replace(":","$")
				}
				
				trap {Write-Host "Error ChildItem $Computer";Continue}
				$ObjectPath += Get-ChildItem "\\$Computer\$Disk\*" -Recurse -ErrorAction SilentlyContinue
					
				if ($ObjectPath){
					
					foreach ($Object in $ObjectsDeleted){
						$ObjectPath | 
						Where-Object {$_.Name -like $Object} | 
						% { $Path = $_.FullName;
							Remove-Item $_.FullName -Recurse -Force -ErrorAction SilentlyContinue;
							$Info += "" | Select-Object @{e={$Path};n='Path'},`
														@{e={"Delete"};n='Action'}
						}
					}
				}
			}
		}
	}
}
$Info | Format-Table -AutoSize -ErrorAction SilentlyContinue
