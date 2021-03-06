#############################################################################################
#
# NAME: Show-SQLServerOperators.ps1
# AUTHOR: Rob Sewell http://sqldbawithabeard.com
# DATE:03/09/2013
#
# COMMENTS: Load function for Enumerating Operators and Notifications
# ————————————————————————

Function Show-SQLServerOperators ($SQLServer) 
{
        Write-Host "############### $SQLServer ##########################"
        Write-Host "#####################################################`n"     

        $server = new-object "Microsoft.SqlServer.Management.Smo.Server" $SQLServer
        
        
            foreach($Operator in $server.JobServer.Operators)
                {
                $Operator = New-Object ("$SMO.Agent.Operator") ($server.JobServer, $Operator)

                $OpName = $Operator.Name
                Write-Host "Operator $OpName"
                Write-Host "`n###### Job Notifications   ######"
                $Operator.EnumJobNotifications()| Select JobName | Format-Table
                Write-Host "#####################################################`n"  
                Write-Host "`n###### Alert Notifications  #######"
                $Operator.EnumNotifications() | Select AlertName | Format-Table
                Write-Host "#####################################################`n"  
                 
                }
 
}  
