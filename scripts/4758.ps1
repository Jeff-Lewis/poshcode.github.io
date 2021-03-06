function Get-ProcessOwner {
  <#
    .EXAMPLE
        PS C:\>Get-ProcessOwner (ps notepad)
    .EXAMPLE
        PS C:\>ps notepad | Get-ProcessOwner
    .NOTES
        Author: greg zakharov
  #>
  [CmdletBinding(SupportsShouldProcess=$true)]
  param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Diagnostics.Process[]]$Processes
  )
  
  begin {
    $StopProcessCommand = ([AppDomain]::CurrentDomain.GetAssemblies() | ? {
      $_.Location.Split('\')[-1].Equals('Microsoft.PowerShell.Commands.Management.dll')
    }).GetType('Microsoft.PowerShell.Commands.StopProcessCommand')
    
    $GetProcessOwnerId = $StopProcessCommand.GetMethod(
      'GetProcessOwnerId', [Reflection.BindingFlags]'NonPublic, Instance'
    )
    
    $type = New-Object $StopProcessCommand
  }
  process {
    $Processes | % {
      if ($PSCmdlet.ShouldProcess(('{0} PID:{1}' -f $_.ProcessName, $_.Id), 'Check owner of process')) {
        try {
          '{0} {1} {2}' -f $_.ProcessName, $_.Id, $GetProcessOwnerId.Invoke($type, $_)
        }
        catch {
          $_.Exception.Message.Split(':')[1].Trim() -replace '\"', ''
        }
      }
    }
  }
  end {
  }
}
