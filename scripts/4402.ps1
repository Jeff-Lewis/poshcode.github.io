function Connect-Session
{
    [CmdletBinding()]
    
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]
        $ComputerName,
        [Management.Automation.PSCredential]
        $Credential,
        # Needs a default setting
        [string]
        $RemoteProfile
    )
    #get FQDN if not provided to let user know where they are connecting
    #also to grab domain for creds
    if($ComputerName -notlike "*.*")
    {
        $fqdn = [net.dns]::GetHostEntry($ComputerName).HostName
        Write-Warning "Connecting to $fqdn"
        ## fqdn doesnt seem to be needed for credssp, leave it out, if it breaks, insert here
    }
    else
    {
        $fqdn=$ComputerName
    }
    
    #no creds provided, search for some
    if(-not $Credential)
    {
        $domain = $fqdn.Substring($fqdn.IndexOf('.')+1)
        $tempc = gv |?{$_.value -is "System.Management.Automation.PSCredential"} | ? {$domain -match $_.value.username.split('\')[0]} | select -First 1
        if($tempc)
        {
            write-verbose "Credentials found in $($tempc.name)"
            $Credential=$tempc.value
        }

    }
    #already an active session?
    if($session = Get-PSSession | ?{$_.ComputerName -eq $computername})
    {
        $credssp = if($session.Runspace.ConnectionInfo.AuthenticationMechanism){$true}
        #its not credssp, can we make it?!
        if(-not $credssp -and $Credential -and [bool](Test-WSMan $computername -Credential $Credential -Authentication Credssp -ea 0))
        {
            Remove-PSSession -Session $session
            $session = New-PSSession -ComputerName $computername -Credential $Credential -Authentication Credssp
        }
        #cant make it, just use it as it is
    }
    else #no session, lets make one
    {
        #can we do credssp
        if($Credential -and [bool](Test-WSMan $computername -Credential $Credential -Authentication Credssp -ea 0))
        {
            $session = New-PSSession -ComputerName $ComputerName -Credential $Credential -Authentication Credssp
        }
        #can we do it with local creds?
        elseif(Test-WSMan $computername)
        {
            $session = New-PSSession -ComputerName $computername -ea 0
        }
        #local creads dont work, try found creds
        
        if(-not $session -and [bool](Test-WSMan -ComputerName $computername -Credential $Credential -Authentication Default))
        {
            $session = New-PSSession -ComputerName $computername -Credential $Credential
        }
        if($session -and $RemoteProfile)
        {
            Invoke-Command -Session $session -FilePath $RemoteProfile
        }
    }

    if($session)
    {
        Write-Verbose "Authentication Method: $($session.Runspace.ConnectionInfo.AuthenticationMechanism)"
        Enter-PSSession $session
    }
    else
    {
        Write-Error "Cant connect to $computername"
    }

}
