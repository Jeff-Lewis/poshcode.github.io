#requires -Version 3
#$PSModuleAutoLoadingPreference = 'None'

#region module management
########################################

# $cloudDrivePath = $null # OneNote, GoogleDrive, DropBox, Carbonite, eieio...

[System.Collections.ArrayList]$Private:moduleList = @(
    #"$cloudDrivePath\PSHModules\PSReadLine\PSReadline.psd1",
    #"$cloudDrivePath\PSHModules\Add-on.CopyAsColorizedHTML\Add-on.CopyAsColorizedHTML.psd1",

    # my function library
    "$cloudDrivePath\PSHModules\Toolkit", 

    "$cloudDrivePath\PSHModules\Pester"
) 

if ($Host.Name -match 'Ise Host') 
{
    $Private:moduleList += "$cloudDrivePath\PSHModules\ISESteroids"
}

$Private:moduleList| ForEach-Object -Process {
    if (Test-Path -Path $_) 
    {
        Import-Module -Force -Name $_ 
    } 
}

########################################
#endregion module management
#region $host.$env:USERNAME session state noteproperty
########################################

if (!$Host.$env:USERNAME)  
{
    Add-Member -InputObject $global:Host -MemberType NoteProperty -Name $env:USERNAME -Value @{} -Force 
}
    
if ($Host.$env:USERNAME.IsAdministrator -eq $null)
{ 
    $CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $CurrentUserPrincipal = New-Object -TypeName Security.Principal.WindowsPrincipal -ArgumentList $CurrentUser
    $AdminRole = [Security.Principal.WindowsBuiltinRole]::Administrator
    $global:Host.$env:USERNAME.IsAdministrator = $CurrentUserPrincipal.IsInRole($AdminRole)
}

if (!($Private:userDomain = $env:USERDNSDOMAIN)) 
{
    $Private:userDomain = $env:USERDOMAIN  
}

$global:Host.$env:USERNAME.UserDomain = $Private:userDomain
$global:Host.$env:USERNAME.ComputerDomain = (Get-WmiObject -Class Win32_ComputerSystem).Domain
$global:Host.$env:USERNAME.Process = Get-Process -Id $pid

########################################
#endregion $host.$env:USERNAME session state noteproperty
#region ISE Preview management
# https://blogs.msdn.microsoft.com/powershell/2016/01/20/introducing-the-windows-powershell-ise-preview/
########################################

$private:staticIsePreviewreleasePath = 'C:\Program Files\WindowsPowerShell\Modules\PowerShellISE-preview\5.1.1\powershell_ise.exe'

if ($psISE.IsPreviewRelease)
{
    if ($private:staticIsePreviewreleasePath -ne $Host.$env:USERNAME.Process.Path)
    {
        Write-Warning -Message 'Need to update outdated $private:staticIsePreviewreleasePath in'
        Write-Warning -Message "    $PSCommandPath from"
        Write-Warning -Message "    $private:staticIsePreviewreleasePath to "
        Write-Warning -Message "    $($Host.$env:USERNAME.Process.Path)"
    }
    $private:staticIsePreviewreleasePath = $Host.$env:USERNAME.Process.Path
}

if (Test-Path -Path $private:staticIsePreviewreleasePath)
{
    # we want the path to persist, but not pollute the user's variable: PSDrive, so we embed it in a scriptblock

    # type 'isep' to start the ISE-Preview
    Set-Content -Path function:Start-IsePreviewRelease -Value ([scriptblock]::Create("Invoke-Item -Path '$private:staticIsePreviewreleasePath'"))
    Set-Alias -Name isep -Value Start-IsePreviewRelease
}

########################################
#endregion ISE Preview management
#region function prompt {}
########################################

<# 
Break the close-multiline-comment tag to un-collapse only this function#>
function prompt
{
    [CmdletBinding()]
    param (
        [switch]$ForceWindowTitle
    )

    #region get PSH window data cached in $Host
    ########################################

    $userDomain = $Host.$env:USERNAME.UserDomain
    $ComputerDomain = $Host.$env:USERNAME.ComputerDomain

    ########################################
    #endregion get PSH window data cached in $Host
    #region get dynamic data
    ########################################

    if ($Host.$env:USERNAME.IsAdministrator) 
    {
        $windowTitleAdminString = 'Administrator: '
        $promptAdminString = '#!#' # for the command prompt line
    }
    else
    {
        $windowTitleAdminString = $null
        $promptAdminString = '#' # for the command prompt line
    }

    if ($history = Get-History | Select-Object -Last 1)
    {
        $lastCommandElapsedTime = ($history.EndExecutionTime - $history.StartExecutionTime).ToString() -replace '\..*'
    }
    else
    {
        $lastCommandElapsedTime = '00:00:00'
    } 

    $historyId = [int]($history.Id) + 1
    $now = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $path = $ExecutionContext.SessionState.Path.CurrentLocation

    ########################################
    #endregion get dynamic data
    #region update the UI
    ########################################

    # set the titlebar if it's default
    if ($ForceWindowTitle -or $Host.UI.RawUI.WindowTitle -match 'Windows PowerShell$') 
    {
        $Host.UI.RawUI.WindowTitle = "$windowTitleAdminString $path [$now]" 
    }

    # set the prompt
    "`n$promptAdminString $userDomain\$env:USERNAME @ $env:computerName.$ComputerDomain $lastCommandElapsedTime ($historyId)".ToLower() +
    "`n$promptAdminString $path $now $('>' * $nestedPromptLevel)>`n"

    ########################################
    #endregion update the UI
} #> # function prompt

<# 
Break the close-multiline-comment tag to un-collapse only this function#>
function Set-DefaultPrompt
{
    {
        "PS $($ExecutionContext.SessionState.Path.CurrentLocation)$('>' * ($nestedPromptLevel + 1)) " 
    } | Set-Content -Path function:prompt
} #> # function Set-DefaultPrompt

<# 
Break the close-multiline-comment tag to un-collapse only this function#>
function Set-SimplePrompt
{
    {
        "PS $($ExecutionContext.SessionState.Path.CurrentLocation) ($(1 + (Get-History | Select-Object -Last 1).Id)) $('>' * ($nestedPromptLevel + 1)) " 
    } | Set-Content -Path function:prompt
} #> # function Set-SimplePrompt

########################################
#endregion function prompt {}
#region catch-all
########################################

# $profile points to "$MyDocuments\WindowsPowerShell\Microsoft.PowerShellISE_profile.ps1" or '...\Microsoft.PowerShell_profile.ps1', but they're empty
# this is where all my setup code goes.  Therefore, typing '. $profile' doesn't work for me.  I type 'ip' to (re)load *this* file
Set-Content -Path function:Invoke-Profile -Value ([scriptblock]::Create(". '$PSCommandPath'"))
Set-Alias -Name ip -Value Invoke-Profile

########################################
#endregion catch-all
#region actual stuff to execute
########################################

# 'Open as Administrator' shells always start in c:\windows\system32, which is a Very Bad Idea
$sys32folder = $env:ComSpec -replace 'cmd\.exe$' -replace '\\', '\\' 
if ((Get-Location).ProviderPath -match "^$sys32folder") 
{
    Set-Location -Path $HOME 
}

$pshFso = Get-Item -Path $Host.$env:USERNAME.Process.Path
Write-Host -ForegroundColor Green -Object "$($pshFso.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')) $($pshFso.FullName) $($Host.$env:USERNAME.Process.FileVersion)"

($PSCommandPath, $profile) |
Where-Object -FilterScript {
    $_ 
} |
ForEach-Object -Process {
    $fso = Get-Item -Path $_
    Write-Host -ForegroundColor Green -Object "$($fso.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')) $($fso.FullName)"
}

$error.Clear()

########################################
#endregion actual stuff to execute
