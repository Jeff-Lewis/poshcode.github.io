﻿$blnCheckSnappin = Get-PSSnapin | where {$_.Name -eq "microsoft.exchange.management.powershell.e2010"}

if ($blnCheckSnappin -eq $null)
{    
    add-pssnapin "microsoft.exchange.management.powershell.e2010" -ErrorVariable errSnapin ;
    . $env:ExchangeInstallPath\bin\RemoteExchange-mod.ps1
    Connect-ExchangeServer -Server <YourExchangeServer> -allowclobber
}
    
Import-Module "$env:programfiles\Common Files\Microsoft Lync Server 2010\Modules\Lync\Lync.psd1"
Import-Module ActiveDirectory

function terminateUser 
{   

    $strMsg1 = ""
    $strMsg2 = ""
    $strMsg3 = ""
    $strMsg4 = ""
    $strMsg5 = ""
    $strUserID = $args[0]
    
    try
    {
        $blnUserExists = get-aduser $strUserID
    }
    catch
    {

    }    

    if($blnUserExists)
    {
        $strMsg3 += "`r`n` "
    	$strMsg3 += "Are you sure you wish to continue? (Y/N) `r`n` "        
        $strMsg3 += "`r`n` "

        $strContinue = read-host $strMsg3
        
        if($strContinue -eq "Y")
        {   			
            $strRunLog = "$strRunDir\Logs\$strUserID-log-$strDate.txt"
            $arrAttachments = @($strRunLog)
            
            start-transcript -path $strRunLog | Out-null

   			# This section will remove the Lync account `r`n` "
                        
            Disable-CSuser -identity $strUserID 
             
            # This section will disable the Exchange account `r`n` "

            Get-InboxRule -Mailbox $strUserID  | Remove-InboxRule -Confirm:$false -Force        
            Set-CASMailbox -Identity $strUserID -ActiveSyncEnabled:$False -OWAEnabled:$False
            Get-ActiveSyncDevice –Mailbox $strUserID | Remove-ActiveSyncDevice -Confirm:$False          
            Set-mailbox -Identity $strUserID -HiddenFromAddressListsEnabled:$true -ForwardingAddress $Null
            
                    
            # This section will move & disable the AD object account `r`n` "
            
            Get-ADPrincipalGroupMembership -Identity $strUserID | Select-object name | format-table
                                     
            Get-ADPrincipalGroupMembership -Identity $strUserID | Where {$_.Name -ne "Domain Users"} | ForEach-Object {Remove-ADPrincipalGroupMembership -Identity $strUserID -MemberOf $_.SamAccountName -Confirm:$False}
            
            Set-ADuser -identity $strUserID -Manager $Null
            Disable-ADAccount -identity $strUserID 
            Get-ADUser -identity $strUserID | Move-ADobject -TargetPath "OU=Disabled,OU=Users,OU=Client,DC=YOURCOMPANY,DC=com,DC=au"                                
            
            $strMsg4 += "`r`n` "    		
            $strMsg4 += "The Termination script for",$strUserID,"has completed. `r`n` "
            $strMsg4 += " `r`n` "
            $strMsg4 += "A log of the session can be located at: $strRunLog. `r`n` "
            $strMsg4 += "`r`n` "    		
            
            Write-host $strMsg4                                                     
            
            $strSubject = "Account Termination Log - $strUserID - Operation Successful"                                             
                        
            stop-transcript | Out-null
            
            start-process notepad.exe $strRunLog
                        
            send-MailMessage -SmtpServer $strSMTPserver -To $arrRecipient -From $strFrom -Subject $strSubject -attachments $arrAttachments -Priority high 
            
            $strMsg5 += "`r`n` "
        	$strMsg5 += "User account terminated. Do you wish to terminate another account? (Y/N) `r`n` "
            $strMsg5 += "`r`n` "
            $strMsg5 += "`r`n` "

            $strContinue = read-host $strMsg5
            
            if($strContinue -eq "Y")
            {
                enterUser
            }
            else
            {
                [System.Windows.Forms.MessageBox]::Show("Exiting Script. ","Status")    
            }                
        }
        else
        {
            [System.Windows.Forms.MessageBox]::Show("Exiting Script. ","Status")  
        }        

    }
    else
    {
        [System.Windows.Forms.MessageBox]::Show("ERROR. $strUserID does not exist in AD. Exiting script. ","Status")  
    }
 }    
 
 function enterUser
 {
 
     $strMsg2 += "`r`n` "
     $strMsg2 += "Please enter the user's AD Account Below: `r`n` "
     $strMsg2 += "`r`n` "
     
     $strUserID = read-host $strMsg2
     $strUserID = $strUserID.Trim()

     terminateUser $strUserID
 }        

[console]::ForegroundColor = "yellow"

# User Termination Process Script for <YourCompany>
# 
# Created by EBS Platforms Team - 2014
#
# Script will read in userid & output results to a text file
# EXAMPLE: UserTermination.ps1
#
# This script will accomplish the following:
#  A) Disable Lync Account (Lync 2010)
#  B) Remove Inbox Rules (Exchange 2010)
#  C) Remove all Mail Forwarding Rules (Exchange 2010)
#  D) Hide email address from Exchange Address Lists (Exchange 2010)
#  E) Remove Group Membership (including DL) from AD object (Active Directory)
#  F) Remove Manager Field from AD object (Active Directory)
#  G) Disable Account (Active Directory)
#  H) Move disabled AD object to Disabled OU
#
# Ask for userid & query if action is correct

[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-null

#
# Declare variables
#

$StrInvocation = (Get-Variable MyInvocation).Value
$strRunDir = Split-Path $StrInvocation.MyCommand.Path
$strDate = get-date -format "dd-MMM-yyyy-HHmm"
$blnUserExists = $false
$strUserID = ""
$strSMTPserver = "<YourMailServer>"  
$strFrom = "<YourAddress>"    
$arrRecipient = @("<YourRecipients>")
$strSubject = ""
$strDebug = ""
$strOperator = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

$strMsg1 += "`r`n` "
$strMsg1 += "User Termination Process Script for <YourCompany> `r`n` "
$strMsg1 += "`r`n` "
$strMsg1 += "Created by EBS Platforms Team - 2014 `r`n` "
$strMsg1 += "`r`n` "
$strMsg1 += "This script will accomplish the following: `r`n` "
$strMsg1 += "`r`n` "
$strMsg1 += "1.) Disable Lync Account (Lync 2010) `r`n` "
$strMsg1 += "2.) Remove Inbox Rules (Exchange 2010) `r`n` "
$strMsg1 += "3.) Remove all Mail Forwarding Rules (Exchange 2010) `r`n` "
$strMsg1 += "4.) Hide email address from Exchange Address Lists (Exchange 2010) `r`n` "
$strMsg1 += "5.) Remove Group Membership (including DL) from AD object (Active Directory) `r`n` "
$strMsg1 += "6.) Remove Manager Field from AD object (Active Directory) `r`n` "
$strMsg1 += "7.) Disable Account (Active Directory) `r`n` "
$strMsg1 += "8.) Move disabled AD object to Disabled OU `r`n` "

write-host $strMsg1

enterUser






