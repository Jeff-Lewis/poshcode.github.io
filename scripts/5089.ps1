

$servers=get-content c:\temp\serverlist.txt 
$username="username" 
$description="temp account for username Patel 4/17/2014" 
$password="password" 
 
foreach ($server in $servers) { 
    if(Test-Connection $server -Count 1) { 
        [ADSI]$remcomp="WinNT://$server" 
        $Account=$remcomp.create("User",$username) 
        $Account.SetPassword($password) 
        $Account.Put("Description",$description) 
       # $PwNoExpFlag=$Account.userflags.value -bor 0x10000 
        #$Account.Put("userflags", $PwNoExpFlag) 
        $Account.SetInfo() 
        [ADSI]$GroupN="WinNT://$server/Administrators,Group" 
        $GroupN.Add($Account.Path) 
    } 
    ELSE {Write-Host "$server is not online, cant add user"}
	} 

