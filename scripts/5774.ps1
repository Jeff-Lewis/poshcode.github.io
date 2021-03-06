gci 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList' | % {
  if (($ta = [Type]::GetType(
    'System.Management.Automation.TypeAccelerators'
  )).Get.Keys -notcontains 'marshal') {
    $ta::Add('marshal', [Runtime.InteropServices.Marshal])
  }
  
  $ToDateTime = {
    param([Int32]$low, [Int32]$high)
    
    if ($low -ne $null -and $high -ne $null) {
      $ft = New-Object Runtime.InteropServices.ComTypes.FILETIME
      $ft.dwLowDateTime = $low
      $ft.dwHighDateTime = $high
      
      try {
        $ptr = [Marshal]::AllocHGlobal([Marshal]::SizeOf($ft))
        [Marshal]::StructureToPtr($ft, $ptr, $false)
        [DateTime]::FromFileTime([Marshal]::ReadInt64($ptr))
      }
      catch {}
      finally {
        if ($ptr -ne [IntPtr]::Zero) { [Marshal]::FreeHGlobal($ptr) }
      }
    }
    else { 'n\a' }
  }
}{
  New-Object PSObject -Property @{
    Name = (New-Object Security.Principal.SecurityIdentifier($_.PSChildName)).Translate(
      [Security.Principal.NTAccount]
    )
    ProfileLoaded = & $ToDateTime ($t = gp $_.PSPath).ProfileLoadTimeLow $t.ProfileLoadTimeHigh
    ProfilePath = $t.ProfileImagePath
  }
}{
  [void]$ta::Remove('marshal')
}
