#
# Filename: Subversion.psm1
# Created:  2014-05-14
# Version:  0.1
# Author:   Frank Peter Schultze
#
# Requires the Subversion command-line binary svn.exe
#
# The exposed functions provide only basic functionality and were successfully tested with the
# subversion command line client from http://www.collab.net/downloads/subversion.
#
# DISCLAIMER: This PowerShell module is provided "as is", without any warranty, whether express
# or implied, of its accuracy, completeness, fitness for a particular purpose, title or non-
# infringement, and none of the third-party products or information mentioned in the work are
# authored, recommended, supported or guaranteed by me. Further, I shall not be liable for any
# damages you may sustain by using this module, whether direct, indirect, special, incidental or
# consequential, even if it has been advised of the possibility of such damages.
#

<#
    .SYNOPSIS
        Wrapper function for "svn.exe update"

    .DESCRIPTION
        Bring the latest changes from the repository into the working copy (HEAD revision).

    .PARAMETER  Path
        The Path parameter identifies the directory of the working copy.

    .EXAMPLE
        Update-SvnWorkingCopy -Path .\myProject
#>
function Update-SvnWorkingCopy
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [String]
        $Path
    )
    svn.exe update "$Path"
}
Set-Alias -Name udsvnwc -Value Update-SvnWorkingCopy

<#
    .SYNOPSIS
        Wrapper function for "svn.exe commit"

    .DESCRIPTION
        Send changes from your working copy to the repository.

    .PARAMETER  Path
        The Path parameter identifies the directory of the working copy.

    .PARAMETER  Message
        The Message parameter identifies a log message. If it is not given PowerShell will prompt for it.

    .EXAMPLE
        Publish-SvnWorkingCopy -Path .\myProject -Message 'Fixed bug #456'
#>
function Publish-SvnWorkingCopy
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [String]
        $Path
        ,
        [Parameter(Mandatory=$true)]
        [String]
        $Message
    )
    svn.exe commit "$Path" --message "$Message"
}
Set-Alias -Name pbsvnwc -Value Publish-SvnWorkingCopy

<#
    .SYNOPSIS
        Wrapper function for "svn.exe import"

    .DESCRIPTION
        Commit an unversioned file or directory tree into the repository.

    .PARAMETER  Path
        The Path parameter identifies the path of an unversioned file or directory tree. If it is not given '.' is assumed.

    .PARAMETER  Url
        The Url parameter identifies the URL of the Subversion repository.

    .PARAMETER  Message
        The Message parameter identifies a log message. If it is not given 'Import' is assumed.

    .EXAMPLE
        Import-SvnUnversionedFilePath -Path .\myProject -Url https://myserver/svn/myrepo
#>
function Import-SvnUnversionedFilePath
{
    [CmdletBinding()]
    Param
    (
        [Parameter()]
        [String]
        $Path = '.'
        ,
        [Parameter(Mandatory=$true)]
        [String]
        $Url
        ,
        [Parameter()]
        [String]
        $Message = 'Import'
    )
    svn.exe import "$Path" "$Url" --message "$Message"
}
Set-Alias -Name ipsvn -Value Import-SvnUnversionedFilePath

<#
    .SYNOPSIS
        Wrapper function for "svn.exe checkout"

    .DESCRIPTION
        Check out a working copy from a repository (HEAD revision).

    .PARAMETER  Url
        The Url parameter identifies the URL of the Subversion repository.

    .PARAMETER  Path
        The Path parameter identifies an non-existing directory for the working copy.

    .EXAMPLE
        New-SvnWorkingCopy -Url https://myserver/svn/myrepo -Path .\myProject
#>
function New-SvnWorkingCopy
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [String]
        $Url
        ,
        [Parameter(Mandatory=$true)]
        [String]
        $Path
    )
    svn.exe checkout "$Url" "$Path"
}
Set-Alias -Name nsvnwc -Value New-SvnWorkingCopy

<#
    .SYNOPSIS
        Wrapper function for "svn.exe status"

    .DESCRIPTION
        Print the status of working copy files and directories.

    .PARAMETER  Path
        The Path parameter identifies the directory of the working copy.

    .EXAMPLE
        Get-SvnWorkingCopy -Path .\myProject
#>
function Get-SvnWorkingCopy
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [String]
        $Path
    )
    svn.exe status "$Path"
}
Set-Alias -Name gsvnwc -Value Get-SvnWorkingCopy

<#
    .SYNOPSIS
        Wrapper function for "svn.exe add"

    .DESCRIPTION
        Put files and directories under version control, scheduling them for addition to repository in next commit.

    .PARAMETER  Path
        The Path parameter identifies the file or directory to be put under version control.

    .EXAMPLE
        Add-SvnWorkingCopyItem -Path .\myProject\final.txt
#>
function Add-SvnWorkingCopyItem
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [String]
        $Path
    )
    svn.exe add "$Path"
}
Set-Alias -Name asvnwci -Value Add-SvnWorkingCopyItem

<#
    .SYNOPSIS
        Wrapper function for "svn.exe delete"

    .DESCRIPTION
        Remove files and directories from version control. Each item specified by Path is scheduled for deletion upon the next commit. Items that have not been committed, are immediately removed from the working copy.

    .PARAMETER  Path
        The Path parameter identifies the file or directory to be removed from version control.

    .EXAMPLE
        Remove-SvnWorkingCopyItem -Path .\myProject\test.txt
#>
function Remove-SvnWorkingCopyItem
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [String]
        $Path
    )
    svn.exe delete "$Path"
}
Set-Alias -Name rsvnwci -Value Remove-SvnWorkingCopyItem

<#
    .SYNOPSIS
        Fix a working copy that has been modified by non-svn commands in terms of adding and removing files.

    .DESCRIPTION
        Identify items that are not under version control and items that are missing (i.e. removed by non-svn command).
        Put non-versioned items under version control (i.e. schedule for adding upon next commit).
        Remove missing items from version control (i.e. schedule for deletion upon next commit).

    .PARAMETER  Url
        The Url parameter identifies the URL of the Subversion repository.

    .PARAMETER  Path
        The Path parameter identifies the directory of the working copy.

    .EXAMPLE
        Repair-SvnWorkingCopy -Path .\myProject
#>
function Repair-SvnWorkingCopy
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [String]
        $Path
    )

    Set-Variable -Name C_SVN_ITEM_MISSING -Value '!' -Option ReadOnly
    Set-Variable -Name C_SVN_ITEM_UNKNOWN -Value '?' -Option ReadOnly

    Get-SvnWorkingCopy -Path $Path |
        Where-Object {$_ -match '^(?<Status>\S)\s+(?<File>\S+)$'} |
            ForEach-Object {
                $Status = $Matches.Status
                $File   = $Matches.File
                switch ($Status)
                {
                    $C_SVN_ITEM_MISSING
                    {
                        Remove-SvnWorkingCopyItem -Path "$File"
                    }
                    $C_SVN_ITEM_UNKNOWN
                    {
                        Add-SvnWorkingCopyItem -Path "$File"
                    }
                }
            }
}

Export-ModuleMember -Function * -Alias *

