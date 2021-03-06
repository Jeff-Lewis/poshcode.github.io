function Add-Junction {
  <#
    .DESCRIPTION
        Windows junction creator.
    .EXAMPLE
        C:\> $junc = [Environment]::GetFolderPath([Environmetn+SpecialFolder]::Desktop) + '\foo'
        C:\> Add-Junction $junc E:\bar
    .NOTES
        Author: greg zakharov
  #>
  param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateNotNullOrEmpty()]
    [String]$JunctionPoint,
    
    [Parameter(Mandatory=$true, Position=1)]
    [ValidateScript({Test-Path $_})]
    [String]$SourcePath
  )
  
  begin {
    #Marshal accelerator
    if ([Array]($ta = [Type]::GetType(
      'System.Management.Automation.TypeAccelerators'
    ))::Get.Keys -notcontains 'marshal') {
      $ta::Add('marshal', [Type][Runtime.InteropServices.Marshal])
    }
    #CreateFile and DeviceIoControl
    $CreateFile = ($asm = ($all = (
      $cd = [AppDomain]::CurrentDomain).GetAssemblies()) | ? {
        $_.ManifestModule.ScopeName -match '(?:(System.dll)|(System.Data.dll))'
    })[0].GetType(
      'Microsoft.Win32.UnsafeNativeMethods'
    ).GetMethod('CreateFile', [Reflection.BindingFlags]40)
    $DeviceIoControl = $asm[1].GetType(
      'System.Data.SqlTypes.UnsafeNativeMethods'
    ).GetMethod('DeviceIoControl', [Reflection.BindingFlags]40)
    #REPARSE_DATA_BUFFER
    if (!($all | ? {
      $_.FullName.Contains('Junction')
    })) {
      $ctr = [Runtime.InteropServices.MarshalAsAttribute].GetConstructor(
        [Reflection.BindingFlags]20, $null, [Type[]]@([Runtime.InteropServices.UnmanagedType]), $null
      )
      $cnt = @([Runtime.InteropServices.MarshalAsAttribute].GetField('SizeConst'))
      $atr = New-Object Reflection.Emit.CustomAttributeBuilder(
        $ctr, [Runtime.InteropServices.UnmanagedType]30, $cnt, @([Int32]0x3FF0)
      )
      
      $type = (($cd.DefineDynamicAssembly(
        (New-Object Reflection.AssemblyName('Junction')), 'Run'
      )).DefineDynamicModule('Junction', $false)).DefineType(
        'REPARSE_DATA_BUFFER', 'AnsiClass, Class, Public, Sealed, SequentialLayout, BeforeFieldInit'
      )
      [void]$type.DefineField('ReparseTag',           [UInt32], 'Public')
      [void]$type.DefineField('ReparseDataLength',    [UInt16], 'Public')
      [void]$type.DefineField('Reserved',             [UInt16], 'Public')
      [void]$type.DefineField('SubstitudeNameOffset', [UInt16], 'Public')
      [void]$type.DefineField('SubstitudeNameLength', [UInt16], 'Public')
      [void]$type.DefineField('PrintNameOffset',      [UInt16], 'Public')
      [void]$type.DefineField('PrintNameLength',      [UInt16], 'Public')
      
      $unm = $type.DefineField('PathBuffer', [Byte[]], 'Public')
      $unm.SetCustomAttribute($atr)
      
      Set-Variable REPARSE_DATA_BUFFER -Value $type.CreateType() -Option ReadOnly -Scope global
    }
    #readable variables
    $GENERIC_WRITE                = 0x40000000
    $FILE_FLAG_OPEN_REPARSE_POINT = 0x00200000
    $FILE_FLAG_BACKUP_SEMANTICS   = 0x02000000
    $PathPrefix                   = '\??\'
    
    [UInt32]$IO_REPARSE_TAG_MOUNT_POINT = 2684354563
    [UInt32]$FSCTL_SET_REPARSE_POINT    = 0x000900A4
  }
  process {
    $SorcePath = Convert-Path $SourcePath
    if (Test-Path $JunctionPoint) {
      Write-Warning "could not create junction point."
      return
    }
    
    try {
      New-Item $JunctionPoint -ItemType Directory | Out-Null
      if (($sfh = $CreateFile.Invoke($null,
        @($JunctionPoint,
          $GENERIC_WRITE,
          7, #FileShare.ReadWrite | FileShare.Delete
          [IntPtr]::Zero,
          3, #FileMode.Open
          ($FILE_FLAG_OPEN_REPARSE_POINT -bxor $FILE_FLAG_BACKUP_SEMANTICS),
          [IntPtr]::Zero
        )
      )).IsInvalid) {
        Remove-Item $JunctionPoint
        [Marshal]::ThrowExceptionForHR([Marshal]::GetHRForLastWin32Error())
      } #if
      
      $bts = [Text.Encoding]::Unicode.GetBytes($PathPrefix + $SourcePath)
      $rdb = [Activator]::CreateInstance($REPARSE_DATA_BUFFER)
      $rdb.ReparseTag           = $IO_REPARSE_TAG_MOUNT_POINT
      $rdb.ReparseDataLength    = [UInt16]($bts.Length + 12)
      $rdb.SubstitudeNameOffset = [UInt16]0
      $rdb.SubstitudeNameLength = [UInt16]$bts.Length
      $rdb.PrintNameOffset      = [UInt16]($bts.Length + 2)
      $rdb.PrintNameLength      = [UInt16]0
      $rdb.PathBuffer           = New-Object "Byte[]" 0x3FF0
      
      [Array]::Copy($bts, $rdb.PathBuffer, $bts.Length)
      $ptr = [Marshal]::AllocHGlobal(([Marshal]::SizeOf($rdb)))
      [Marshal]::StructureToPtr($rdb, $ptr, $false)
      if (!($DeviceIoControl.Invoke($null,
        @($sfh,
          $FSCTL_SET_REPARSE_POINT,
          $ptr,
          [UInt32]($bts.Length + 20),
          [IntPtr]::Zero,
          [UInt32]0,
          [UInt32]$ret,
          [IntPtr]::Zero
        )
      ))) {
        [Marshal]::ThrowExceptionForHR([Marshal]::GetHRForLastWin32Error())
      }
    }
    catch { $_ }
    finally {
      if ($ptr -ne $null) { [Marshal]::FreeHGlobal($ptr) }
      if ($sfh -ne $null) { $sfh.Close() }
    }
  }
  end {
    [void]$ta::Remove('marshal')
  }
}
