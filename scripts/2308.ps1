<?xml version="1.0" encoding="UTF-8" ?>
<Configuration version="1.0">

<Feature Name="MailboxProvisioningDatabase" Cmdlets="new-mailbox">
  <ApiCall Name="ProvisionDefaultProperties">

#Regex switch to decide mailboxdatabase based on the user specified Name-attribute
switch -regex (($provisioningHandler.UserSpecifiedParameters["Name"]).substring(0,1)) 
    { 
       "[A-F]" {$databasename = "MDB A-F"} 
       "[G-L]" {$databasename = "MDB G-L"} 
       "[M-R]" {$databasename = "MDB M-R"} 
       "[S-X]" {$databasename = "MDB S-X" } 
       "[Y-Z]" {$databasename = "MDB Y-Z" } 
        default {$databasename = "MDB Y-Z" }
    }


#New template recipient
$user = new-object -type Microsoft.Exchange.Data.Directory.Recipient.ADUser;

#The template recipient are provided a database based on the result of the regex switch
$user.database = "CN=$databasename,CN=Databases,CN=Exchange Administrative Group (FYDIBOHF23SPDLT),CN=Administrative Groups,CN="Exchange organization name",CN=Microsoft Exchange,CN=Services,CN=Configuration,DC=domain,DC=local";

#The template recipient are provided as an argument to a new template mailbox which will be used by the New-Mailbox cmdlet
new-object -type Microsoft.Exchange.Data.Directory.Management.Mailbox -argumentlist $user

  </ApiCall>
 </Feature>

</Configuration>
