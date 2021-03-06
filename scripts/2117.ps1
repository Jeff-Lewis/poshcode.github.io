#Get information on everybodies inbox and spit it out with total sizes #in MB.  Sorts the list by StorageLimitStatus
#NOTE THAT I HAD TO USE ASCII WITH OUT-FILE AS NO OTHER ENCODING WOULD #PROPERLY IMPORT CSV INTO EXCEL

#create a date var to stick in the filename
$date = get-date -Format MM-dd-yyyy

#create a outfile var so we only have to update it in one spot
$OUTFILE = "C:\Net_Admin_Stuff\usage_reports\daily_storage_limits\Daily_Storage_Limits-$date.csv" 

#Create the default db send/receive quota divided by 1024 to convert KB to MB.
$DEFAULTSENDQUOTA = 510000/1024

#Create a header to display at the top.
$HEADER = "Display Name,Storage Limit Status,Item Count,Total Item Size (MB),Deleted Item Count,Total Deleted Item Size (MB),Prohibit Send/Receive Quota (MB),Quota Source"
$HEADER | Out-File $OUTFILE -Append -Encoding Ascii

#Get mailbox stats for all users, sort by Storage Limit Status and go through each users objects
Get-MailboxStatistics |  where {$_.ObjectClass -eq 'Mailbox'} | Sort-Object StorageLimitStatus | ForEach-Object {		
	#Get the current user so we can grab some information from the get-mailbox command	
	$CURUSER = get-mailbox -Identity $_.Identity   

	#if the current user is using db defaults it will show a value of unlimited, which can't be calculated.    
	#Push the default value into the field when this happens  
	#Label where the source of the quota came from	
	If ($CURUSER.UseDatabaseQuotaDefaults -eq $true) 
	{
 		$QUOTASRC = $CURUSER.Database	  
		$SENDQUOTA = $DEFAULTSENDQUOTA	
	}   
	else  
	{    
		$QUOTASRC = "User Profile"    
		$SENDQUOTA = $CURUSER.ProhibitSendReceiveQuota.Value.ToMB()	  
	}	

	#Generate useable vars for each of the objects that we're going to work with.	
	$DNAME = $_.DisplayName;	
	$SLSTATUS = $_.StorageLimitStatus;	
	$ICOUNT = $_.ItemCount;	
	$TISIZE = $_.TotalItemSize.Value.ToMB();	
	$DICOUNT = $_.DeletedItemCount;	
	$TDISIZE = $_.TotalDeletedItemSize.Value.ToMB();	

	#spit out our information into a single row	
	"$DNAME,$SLSTATUS,$ICOUNT,$TISIZE,$DICOUNT,$TDISIZE,$SENDQUOTA,$QUOTASRC" 
} | Out-File $OUTFILE -Append -Encoding Ascii
