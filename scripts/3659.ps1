Param (
[Parameter(Mandatory=$true, Position=1)][string] $SourceServer,
[Parameter(Mandatory=$true, Position=2)][string] $SourceZone,
[Parameter(Mandatory=$true, Position=3)][string] $DestinationServer,
[Parameter(Mandatory=$true, Position=4)][string] $DestinationZone,
[string[]] $RRtypes = @("MicrosoftDNS_AType"),
[switch] $Copy,
[switch] $Clean,
[switch] $Help
)

# script variables
$nl = [Environment]::NewLine

If ($Help){
    Write-Host -ForegroundColor Green "
NAME
    DNS_Functions
SYNOPSIS
    Copies and/or cleans DNS records from one forward zone to another
SYNTAX
    .\DNS_Functions SourceServer SourceZone DestinationServer DestinationZone Switches
	
EXAMPLES
     Forward zone comparison report only:
      .\DNS_Functions $SourceServer $SourceZone $DestinationServer $DestinationZone
	  
     Forward source zone clean up for CNAME records:
	  .\DNS_Functions.ps1 source_dnsserver source_zone.local destination_dnsserver destination_zone.local -RRtypes `"MicrosoftDNS_AType`",`"MicrosoftDNS_CNAMEType`" -Clean
	  
DESCRIPTION
    This script can both copy and clean DNS records by comparing any 2 DNS zones, either same or different FQDN
	"
	break
}

function GetDNSrecords($DNSserver, $DNSzone, $RRtype){
	if ($RRtype -eq $null){$RRtype = "MicrosoftDNS_ResourceRecord"}
	$DNSrecords = Get-WMIObject -Computer $DNSserver -Namespace "root\MicrosoftDNS" -Class $RRtype -Filter "ContainerName='$DNSzone'"
	if ($DNSrecords){
		Switch ($RRtype){
			MicrosoftDNS_AType {
				foreach ($rec in $DNSrecords){
					# add simple name of dns record as extra property for comparison routine
					Add-Member -InputObject $rec -MemberType NoteProperty -Name SimpleVal -Value $rec.OwnerName.Replace(".$DNSzone","")
					}
				}
			MicrosoftDNS_CNAMEType {
				foreach ($rec in $DNSrecords){
					# add simple name of dns record as extra property for comparison routine
					Add-Member -InputObject $rec -MemberType NoteProperty -Name SimpleVal -Value $rec.OwnerName.Replace(".$DNSzone","")
					}
				}
			MicrosoftDNS_ResourceRecord {
				# to be implemented
				}
			}
		}
	return $DNSrecords
}

function GetDNSrecord ($DNSserver, $DNSzone, $name, $RRtype){
	$DnSrecord = Get-WMIObject -Computer $DNSserver -Namespace "root\MicrosoftDNS" -Class $RRtype -Filter "OwnerName='$name.$DNSzone'"
	return $DNSrecord # returns the actual object for further processing
}

function GetDNSzones($DNSserver){
	# server side filtering
	$DNSzones = Get-WmiObject -ComputerName $DNSserver -Class MicrosoftDNS_Zone -Namespace root\microsoftDNS -Filter "ZoneType = 1 or ZoneType = 2"
	# client side filtering
	#$destDNSzone = Get-WmiObject -ComputerName $destServer -Class MicrosoftDNS_Zone -Namespace root\microsoftDNS | Where {$_.ZoneType -eq '1' -or  $_.ZoneType -eq '2'}
	return $DNSzones
}

function GetDNSzone ($DNSserver, $name){
	$DnSzone = Get-WMIObject -Computer $DNSserver -Namespace "root\MicrosoftDNS" -Class MicrosoftDNS_Zone -Filter "Name='$name'"
	return $DnSzone # returns the actual object for further processing
}

# just for debugging and reference
function DNSrecordInfo($DNSrecord){
	$objOutput = New-Object PSObject -Property @{
		$class			= $DNSrecord.__CLASS			# A, CNAME, PTR, etc.
		$ownerName		= $DNSrecord.OwnerName			# Name column in DNS GUI, FQDN
		$containerName	= $DNSrecord.ContainerName		# Zone FQDN
		$domainName		= $DNSrecord.DomainName			# Zone FQDN
		$ttl			= $DNSrecord.TTL				# TTL
		$recordClass	= $DNSrecord.RecordClass		# Usually 1 (IN)
		$recordData		= $DNSrecord.RecordData			# Data column in DNS GUI, value
		$simpleval		= $ownerName.Replace(".$domainName","")
		}
	return $objOutput
}

function CopyRecords($DNSrecords){
	Write-Output "$($nl)$('Copying') $($DNSrecords.count) $('records to') $($DestinationServer)$($nl)"
	$Succ = $Fail = 0
	foreach ($DnSrecord in $DNSrecords){
		Switch ($DNSrecord.__CLASS) {
			MicrosoftDNS_AType {
				$destRec = [WmiClass]"\\$DestinationServer\root\MicrosoftDNS:MicrosoftDNS_AType"
				if ($Copy){
					if ($DnSrecord.SimpleVal -eq $SourceZone){
						# skip (same as parent) A records
						Write-Output "$('copy of A:') $($DNSrecord) $('skipped')"
						break
						}
					try{
						$newrec = $DNSrecord.SimpleVal + "." + $DestinationZone
						$destRec.CreateInstanceFromPropertyData($DestinationServer, $DestinationZone, $newrec, 1, $DNSrecord.TTL, $DNSrecord.RecordData) | out-null
						$Succ ++
						Write-Output "$('copy of A:') $($newrec) $('on') $($DestinationServer)"
						}
					catch{
						Write-Output "$('copy of A:') $($newrec) $('failed')"
						Write-Output "$($error[0])"
						$Fail ++
						}
					}
				}
			MicrosoftDNS_CNAMEType {
				$destRec = [WmiClass]"\\$DestinationServer\root\MicrosoftDNS:MicrosoftDNS_CNAMEType"
				if ($Copy){
					try{
						$newrec = $DNSrecord.SimpleVal + "." + $DestinationZone
						$crec = $DNSrecord.RecordData.Replace(".$SourceZone",".$DestinationZone")
						$destRec.CreateInstanceFromPropertyData($DestinationServer, $DestinationZone, $newrec, 1, $DNSrecord.TTL, $crec ) | out-null
						$Succ ++
						Write-Output "$('copy of CNAME:') $($newrec) $('on') $($DestinationServer)"
						}
					catch{
						Write-Output "$('copy of CNAME') $($newrec) $('failed')"
						Write-Output "$($error[0])"
						$Fail ++
						}
					}
				}
			default{
				Write-Output "$('copy of:') $($DNSrecord.SimpleVal) $('failed') $('due to unknown record class')"
				$Fail ++
				}
			}
		}
	Write-Output "$($nl)$($Succ) $('records copied')"
	Write-Output "$($Fail) $('records failed')$($nl)"
}

function ScavengeRecords($DNSrecords){
	$Deleted = $Dead = $Live = 0
	foreach ($DnSrecord in $DNSrecords){
		if (Test-Connection -ComputerName  $DNSrecord.OwnerName -count 1 -ea silentlycontinue) {
			write-output "$($DNSrecord.SimpleVal) $('is still alive')"
			$Live ++
			}
		else{
			write-output "$($DNSrecord.SimpleVal) $('cannot be reached')"
			$Dead ++
			if ($Clean){
				try{
					$DNSrecord.delete()
					$Deleted ++
					}
				catch{}
				}
			}
		}
	Write-Output "$($nl)$($Deleted) $('records scavenged')"
	Write-Output "$($Live) $('records were live')"
	Write-Output "$($Dead) $('records were dead')$($nl)"
}

function DedupDNSzone ($srcRecords, $dstRecords){
	# return only records from reference (= source zone) found in both DNS zones
	$Records2Dedup = compare-object $srcRecords $dstRecords -IncludeEqual -ExcludeDifferent -Property SimpleVal -PassThru
	Write-Output "$($nl)$('deleting duplicate records from') $($SourceZone)"
	try{
		$Records2Dedup | %{ $_.delete() }
		Write-Output "$($Records2Dedup.count) $('duplicate records processed')$($nl)"
		}
	catch{
		Write-Output "$('failure deleting record(s)')$($nl)"
		}
}

function CleanDNSzone($srcRecords, $dstRecords){
	# return unique records in source zone only
	$Records2Clean = compare-object $srcRecords $dstRecords -Property SimpleVal -PassThru | Where-Object { $_.SideIndicator -eq '<=' }
	ScavengeRecords $Records2Clean
}

function CopyDNSzone ($srcRecords, $dstRecords){
	# return unique records in source zone only
	$Records2Copy = compare-object $srcRecords $dstRecords -Property SimpleVal -PassThru | Where-Object { $_.SideIndicator -eq '<=' }
	CopyRecords $Records2Copy
}

function CompareDNSservers($srcDNSzone ,$destDNSzone){
	$dest = $src = $equ = 0
	$zones = compare-object $srcDNSzone $destDNSzone -Property name -IncludeEqual
	if ($zones -ne $null){
		foreach ($zone in $zones){
			switch ($zone.SideIndicator){
				'=>' {
					write-output "$($zone.Name) $('only exists on destination:') $($DestinationServer)"
					$dest ++
					}
				'<=' {
					write-output "$($zone.Name) $('only exists on source:') $($SourceServer)"
					$src ++
					}
				'==' {
					write-output "$($zone.Name) $('exists on both source and destination')"
					$equ ++
					}
				}
			}
		write-output "$($nl)$($dest) $('zones on') $($DestinationServer) $('only')"
		write-output "$($src) $('zones on') $($SourceServer) $('only')"
		write-output "$($equ) $('zones on both source and destination')$($nl)" 
		}
}

function CompareDNSzone($srcRecords, $dstRecords){
	$dest = $src = $equ = 0
	$records = compare-object $srcRecords $dstRecords -IncludeEqual -Property SimpleVal
	if ($records -ne $null){
		foreach ($record in $records){
			switch ($record.SideIndicator){
				'=>' {
					write-output "$($record.SimpleVal) $('exists only in:') $($DestinationZone)"
					$dest ++
					}
				'<=' {
					write-output "$($record.SimpleVal) $('exists only in:') $($SourceZone)"
					$src ++
					}
				'==' {
					write-output "$($record.SimpleVal) $('exists in both zones')"
					$equ ++
					}
				}
			}
		write-output "$($nl)$($dest) $('records in') $($DestinationZone) $('on') $($DestinationServer) $('only')"
		write-output "$($src) $('records in') $($SourceZone) $('on') $($SourceServer) $('only')"
		write-output "$($equ) $('records in both source and destination')$($nl)" 
		}
}

function GetRecordType($Class){
# return human readable record type :-)
	Switch ($Class) {
		MicrosoftDNS_AAAAType 	{return "AAAA"}
		MicrosoftDNS_AFSDBType 	{return "AFSDB"}
		MicrosoftDNS_ATMAType 	{return "ATMA"}
		MicrosoftDNS_AType 		{return "A"}
		MicrosoftDNS_CNAMEType 	{return "Cname"}
		MicrosoftDNS_HINFOType 	{return "H Info"}
		MicrosoftDNS_ISDNType 	{return "ISDN"}
		MicrosoftDNS_KEYType 	{return "Key"}
		MicrosoftDNS_MBType 	{return "MB"}
		MicrosoftDNS_MDType		{return "MD"}
		MicrosoftDNS_MFType 	{return "MF"}
		MicrosoftDNS_MGType 	{return "MG"}
		MicrosoftDNS_MINFOType 	{return "M Info"}
		MicrosoftDNS_MRType 	{return "MR"}
		MicrosoftDNS_MXType 	{return "MX"}
		MicrosoftDNS_NSType 	{return "NS"}
		MicrosoftDNS_NXTType	{return "NXT"}
		MicrosoftDNS_PTRType	{return "PTR"}
		MicrosoftDNS_RPType 	{return "RP"}
		MicrosoftDNS_RTType 	{return "RT"}
		MicrosoftDNS_SIGType	{return "SIG"}
		MicrosoftDNS_SOAType	{return "SOA"}
		MicrosoftDNS_SRVType	{return "SRV"}
		MicrosoftDNS_TXTType	{return "Text"}
		MicrosoftDNS_WINSRType	{return "Wins R"}
		MicrosoftDNS_WINSType 	{return "Wins"}
		MicrosoftDNS_WKSType 	{return "WKS"}
		MicrosoftDNS_X25Type 	{return "X25"}
		}
}

# actual script execution
write-output "$('Comparison between') $($SourceServer) $('and') $($DestinationServer) $('for all regular DNS zones')$($nl)"
if ($SourceServer -ne $DestinationServer){
	# arrays of DNS zones to compare
	$srcZones = GetDNSzones $SourceServer
	$destZones = GetDNSzones $DestinationServer
	# output of DNS zones found on both servers
	CompareDNSservers $srcZones $destZones
	# run thru loop for all DNS record types in script parameter
	}
else{write-output "$('Source and Destination server are the same')$($nl)"}
	
foreach ($RRtype in $RRtypes){
	if (!(GetRecordType $RRtype)){write-warning "$RRtype is not a valid DNS resource type";continue}
	write-output "$('Comparison between') $($SourceZone) $('on') $($SourceServer) $('and') $($DestinationZone) $('on') $($DestinationServer) $('for') $(GetRecordType $RRtype) $('records')$($nl)"
	# arrays of DNS records to compare
	$sourceRecords = (GetDNSrecords $SourceServer $SourceZone $RRtype)
	$destinRecords = (GetDNSrecords $DestinationServer $DestinationZone $RRtype)
	# check for empty array(s)
	if ($sourceRecords -and $destinRecords){
		# output of DNS records found in both zones
		CompareDNSzone $sourceRecords $destinRecords
		# clean duplicate records on the source server
		DedupDNSzone $sourceRecords $destinRecords
		# copy unique records from source to destination server
		CopyDNSzone $sourceRecords $destinRecords
		#CleanDNSzone $sourceRecords $destinRecords
		}
	else{write-output "$('no') $(GetRecordType $RRtype) $('records in either DNS zone')$($nl)"}
}
write-output "$('end script')$($nl)"
