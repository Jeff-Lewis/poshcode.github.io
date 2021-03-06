function Is-SameSubnet {param(	[string]$IP1,
				[string]$IP2,
				[string]$Subnet = "255.255.255.0")
	
	[string]$IP1Bits = ""
	[string]$IP2Bits = ""
	[string]$SubnetBits = ""
									
	## get string representations of all the bits from the IP's passed in
	[System.Net.IPAddress]::Parse($IP1).GetAddressBytes() |	
		ForEach-Object {
			$Bits = [Convert]::ToString($_, 2)
			## pad bit values with leading zeroes if less than 8 characters
			$IP1Bits += $Bits.Insert(0, "0"*(8-$Bits.Length))
		}
	[System.Net.IPAddress]::Parse($IP2).GetAddressBytes() | 
		ForEach-Object {
			$Bits = [Convert]::ToString($_, 2)
			## pad bit values with leading zeroes if less than 8 characters
			$IP2Bits += $Bits.Insert(0, "0"*(8-$Bits.Length))
		}
	[System.Net.IPAddress]::Parse($Subnet).GetAddressBytes() | 
		ForEach-Object {
			$Bits = [Convert]::ToString($_, 2)
			## pad bit values with leading zeroes if less than 8 characters
			$SubnetBits += $Bits.Insert(0, "0"*(8-$Bits.Length))
		}
	
	## subnets must always begin with all bits in the first octet turned on
	if ($SubnetBits.StartsWith("11111111") -eq $FALSE) {return $FALSE}
	
	$BitPos = 0
	do {
		## compare the bits in the current position of the two IP's
		$Compare = [Convert]::ToInt32($IP1Bits.Substring($BitPos, 1)) -eq [Convert]::ToInt32($IP2Bits.Substring($BitPos, 1))
		## convert that into a string (will be either '0' or '1')
		$Compare = [Convert]::ToString([Convert]::ToInt32($Compare))
		[string]$SubnetBit = $SubnetBits.Substring($BitPos, 1)
		
		if ($SubnetBit -eq "1") {
			if ($Compare -eq $SubnetBit) {$BitPos++} else {return $FALSE}
		} else {break}
	} until ($BitPos -eq $IP1Bits.Length)
	return $TRUE
}
