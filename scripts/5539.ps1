function Test-GACAssembly {
  <#
    .SYNOPSIS
        Check that assembly has been installed in GAC.
    .DESCRIPTION
        It will show you RuntimeException message if assembly has not been
        installed in GAC.
    .EXAMPLE
        PS C:\> Test-GACAssembly System.Web
    .LINK
        http://powershell.com/cs/media/p/40660.aspx
    .NOTES
        Author: greg zakharov
  #>
  param(
    [Parameter(Mandatory=$true)]
    [String]$AssemblyName
  )
  
  begin {
    Add-Type -AssemblyName System.Deployment
    
    $SystemUtils = ([AppDomain]::CurrentDomain.GetAssemblies() | ? {
      $_.ManifestModule.ScopeName.Equals('System.Deployment.dll')
    }).GetType(
      'System.Deployment.Application.Win32InterOp.SystemUtils'
    )
    
    $bf = {param([Int32]$i) [Reflection.BindingFlags]$i}
  }
  process {
    try {
      $Flags = $SystemUtils.GetNestedType('QueryAssemblyInfoFlags', (&$bf 32))
      $AssemblyInfo = $SystemUtils.GetMethod(
        'QueryAssemblyInfo', (&$bf 40)
      ).Invoke(
        $null, @((4 -as $Flags), $AssemblyName) #4 - GetCurrentPath flag
      )
      $AssemblyInfo.GetType().GetField(
        'currentAssemblyPath', (&$bf 36)
      ).GetValue($AssemblyInfo)
    }
    catch {
      $_.Exception
    }
  }
  end {}
}
