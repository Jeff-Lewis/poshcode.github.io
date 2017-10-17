﻿function Ping-Host {param(	[string]$HostName,
							[int32]$Requests = 3)
	
	for ($i = 1; $i -le $Requests; $i++) {
		$Result = Get-WmiObject -Class Win32_PingStatus -ComputerName . -Filter "Address='$HostName'"
		Start-Sleep -Seconds 1
		if ($Result.StatusCode -ne 0) {return $FALSE}
	}
	return $TRUE
}
