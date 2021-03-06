#skrypt agregujace rozne raporty o obiektach AD
#author: voytas
#date: 11.2013



if(!(get-module activedirectory)) {
import-module activedirectory
} 
#else {
#write-host "Uwaga: Modu³ AD juz dodany" -BackgroundColor Cyan
#}

#variables
$inactivedays = 30
$inactivedayscomp = 30
$comptop = 20
$userdname = "ou=users,dc=domain,dc=local"
$compdname = "ou=comps,dc=domain,dc=local"

#users

function userinactive {
write-host ;
write-host "U¿ytkownicy aktywni i czasem nielogowania d³u¿szymy ni¿ $($inactivedays) dni" -ForegroundColor Magenta
$date=(get-date).AddDays(-$inactivedays)
$users=get-aduser `
    -Properties lastlogondate `
    -Filter {enabled -eq $true -and lastlogondate -lt $date -and samaccountname -notlike "*2*" -and samaccountname -notlike "*test*"} `
    -SearchBase $userdname | `
    sort lastlogondate
$users | ft samaccountname, lastlogondate, distinguishedname -AutoSize
write-host "Znalezionych u¿ytkowników: $(($users).count)" -ForegroundColor green
write-host "---------------------------------------------"
write-host ;
}

function userinactivenotloged {
write-host ;
write-host "U¿ytkownicy aktywni i nigdy niezalogowani" -ForegroundColor Magenta
$users=get-aduser `
    -Properties lastlogondate, lastlogontimestamp,whencreated `
    -Filter {enabled -eq $true -and samaccountname -notlike "*2*" -and samaccountname -notlike "*test*"} `
    -SearchBase $userdname | `
    ? {(!$_.lastlogontimestamp -eq "*")}
$users | sort samaccountname | ft samaccountname, distinguishedname, whencreated -AutoSize
write-host "Znalezionych u¿ytkowników: $(($users).count)" -ForegroundColor green
write-host "---------------------------------------------"
write-host ;
}



function compinactive {
#komputery
write-host ;
write-host "Komputery aktywne i czasem nielogowania d³u¿szymy ni¿ $($inactivedays) dni" -ForegroundColor Magenta
$date=(get-date).AddDays(-$inactivedayscomp)
$comps=get-adcomputer `
    -Properties lastlogondate `
    -Filter {enabled -eq $true -and lastlogondate -lt $date -and samaccountname -notlike "*template*" -and samaccountname -notlike "*pool*" -and samaccountname -notlike "*thinapp*"} `
    -SearchBase $compdname | `
    sort lastlogondate
$comps | ft samaccountname, lastlogondate, distinguishedname -AutoSize
write-host "Znalezionych komputerów: $(($comps).count)" -ForegroundColor green
write-host "---------------------------------------------"
write-host ;
}

function compinactivetop {
# komputery top
write-host ;
write-host "Komputery aktywne i czasem nielogowania d³u¿szymy ni¿ $($inactivedays) dni - TOP ($($comptop))" -ForegroundColor Magenta
$date=(get-date).AddDays(-$inactivedayscomp)
$comps=get-adcomputer `
    -Properties lastlogondate `
    -Filter {enabled -eq $true -and lastlogondate -lt $date -and samaccountname -notlike "*template*" -and samaccountname -notlike "*pool*" -and samaccountname -notlike "*thinapp*"} `
    -SearchBase $compdname | `
    sort lastlogondate
$comps | `
    select-object -first $comptop | `
    ft samaccountname, lastlogondate, distinguishedname -AutoSize
write-host "Top $($comptop) z komputerów: $(($comps).count)" -ForegroundColor green
write-host "---------------------------------------------"
write-host ;
}



#main
cls
#userinactive
userinactivenotloged
#compinactive
#compinactivetop
