Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

$ParamObject = new-object PSObject

#User configured parameters
$ParamObject | Add-Member Noteproperty UnattendedAccount "es2\es2admin" -force #this must be the unattended service account that you wish to use
$ParamObject | Add-Member Noteproperty PassPhrase "ZxpNix902Z01" -force #you can change this to any passphrase that you want

$ParamObject | Add-Member Noteproperty ContextUrl "http://urlgoeshere" -force #add a url for the Secure Store Service context (default url of the web application)

# system defined parameters - do not modify
$ParamObject | Add-Member Noteproperty SecureApplicationProxy ((Get-SPServiceApplicationProxy | Where { $_.Displayname -Like "Secure*"})) -Force

#create key - first the application proxy must be located
$ssApplicationProxy = Get-SPServiceApplicationProxy | Where { $_.Displayname -like "Secure*"}
# creating key
Update-SPSecureStoreMasterKey -ServiceApplicationProxy $ParamObject.SecureApplicationProxy -PassPhrase $ParamObject.PassPhrase > $null
Start-Sleep 5
Update-SPSecureStoreApplicationServerKey -ServiceApplicationProxy $ParamObject.SecureApplicationProxy -Passphrase $ParamObject.PassPhrase > $null
Start-Sleep 5

#Get the Visio Service App
$svcApp = Get-SPServiceApplication | where {$_.TypeName -like "*Visio*"}
#Get the existing unattended account app ID
$unattendedServiceAccountApplicationID = ($svcApp | Get-SPVisioExternalData).UnattendedServiceAccountApplicationID

$ParamObject | Add-Member Noteproperty UnattendedAccountId $unattendedServiceAccountApplicationID -Force
$ParamObject | Add-Member Noteproperty VisioServiceApplication ((Get-SPServiceApplication | Where { $_.DisplayName -like "Visio*"})) -Force

#If the account isn't already set then set it
if ([string]::IsNullOrEmpty($unattendedServiceAccountApplicationID)) {
    #Get our credentials
    $unattendedAccount = Get-Credential $ParamObject.UnattendedAccount

    #Set the Target App Name and create the Target App
    $name = "$($svcApp.ID)-VisioUnattendedAccount"
    Write-Host "Creating Secure Store Target Application $name..."
    $secureStoreTargetApp = New-SPSecureStoreTargetApplication -Name $name `
        -FriendlyName "Visio Services Unattended Account Target App" `
        -ApplicationType Group `
        -TimeoutInMinutes 3

    #Set the group claim and admin principals
    $groupClaim = New-SPClaimsPrincipal -Identity "nt authority\authenticated users" -IdentityType WindowsSamAccountName
    $adminPrincipal = New-SPClaimsPrincipal -Identity "$($env:userdomain)\$($env:username)" -IdentityType WindowsSamAccountName

    #Set the account fields
    $usernameField = New-SPSecureStoreApplicationField -Name "User Name" -Type WindowsUserName -Masked:$false
    $passwordField = New-SPSecureStoreApplicationField -Name "Password" -Type WindowsPassword -Masked:$false
    $fields = $usernameField, $passwordField

    #Set the field values
    $secureUserName = ConvertTo-SecureString $unattendedAccount.UserName -AsPlainText -Force
    $securePassword = $unattendedAccount.Password
    $credentialValues = $secureUserName, $securePassword

    #Get the service context
    $subId = [Microsoft.SharePoint.SPSiteSubscriptionIdentifier]::Default
    $context = [Microsoft.SharePoint.SPServiceContext]::GetContext($svcApp.ServiceApplicationProxyGroup, $subId)

    #Check to see if the Secure Store App already exists
    $secureStoreApp = Get-SPSecureStoreApplication -ServiceContext $context -Name $name -ErrorAction SilentlyContinue
    if ($secureStoreApp -eq $null) {
        #Doesn't exist so create.
        Write-Host "Creating Secure Store Application..."
        $secureStoreApp = New-SPSecureStoreApplication -ServiceContext $context `
            -TargetApplication $secureStoreTargetApp `
            -Administrator $adminPrincipal `
            -CredentialsOwnerGroup $groupClaim `
            -Fields $fields
    }
    #Update the field values
    Write-Host "Updating Secure Store Group Credential Mapping..."
    Update-SPSecureStoreGroupCredentialMapping -Identity $secureStoreApp -Values $credentialValues
    
    $ParamObject 
    
    #Set the unattended service account application ID
    $svcApp | Set-SPVisioExternalData -UnattendedServiceAccountApplicationID $name
}

# Configure the Visio Service Application
Set-SPVisioPerformance –MaxDiagramCacheAge 10 –MaxCacheSize 5120 –MaxDiagramSize 15 –MaxRecalcDuration 60 –MinDiagramCacheAge 1 –VisioServiceApplication $ParamObject.VisioServiceApplication
Set-SPVisioExternalData -VisioServiceApplication $ParamObject.VisioServiceApplication -UnattendedServiceAccountApplicationID $ParamObject.UnattendedAccountId
cls
Write-Host "Done..."

