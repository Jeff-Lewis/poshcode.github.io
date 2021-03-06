function Get-PEHeader {
  <#
    .EXAMPLE
        PS C:\debug> (Get-PEHeader app.exe).DosHeader
    .EXAMPLE
        PS C:\debug> (Get-PEHeader app.exe).FileHeader
    .EXAMPLE
        PS C:\debug> (Get-PEHeader app.exe).OptionalHeader
    .EXAMPLE
        PS C:\debug> (Get-PEHeader app.exe).DataDirectories
    .EXAMPLE
        PS C:\debug> (Get-PEHeader app.exe).Sections
    .NOTES
        Author: greg zakahrov
  #>
  param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [ValidateScript({Test-Path $_})]
    [String]$File
  )
  
  begin {
    Add-Type -AssemblyName Microsoft.Build.Tasks, System.Deployment
    
    $assemblies = [AppDomain]::CurrentDomain.GetAssemblies() | ? {
      $_.ManifestModule.ScopeName -match '(?:(Microsoft.Build.Tasks)|(System.Deployment).dll)'
    }
    #some useful functions for quick accessing and parsing data
    $flag = {param([Int32]$i) [Reflection.BindingFlags]$i}
    $type = {param([String]$a, [String]$t)
      ($assemblies | ? {$_.FullName.Contains($a)}).GetType($t)
    }
    $strc = {param([String]$s)
      [Activator]::CreateInstance(
        (&$type ($a = 'System.Deployment') ($a + '.Application.PEStream')).GetNestedType(
          $s, (&$flag 32)
        )
      )
    }
    $NativeMethods = &$type ($a = 'Microsoft.Build.Tasks') ($a + '.NativeMethods')
    $nthdr = {param([Int32]$bit)
      [Activator]::CreateInstance(
        $NativeMethods.GetNestedType(('IMAGE_NT_HEADERS' + $bit), (&$flag 32))
      )
    }
    $field = {param([Object]$o, [String]$f)
      $o.GetType().GetField($f, (&$flag 36)).GetValue($o)
    }
    
    $File = Convert-Path $File
    #marshal accelerator
    if ([Array]($script:ta = [Type]::GetType(
      'System.Management.Automation.TypeAccelerators'
    ))::Get.Keys -notcontains 'marshal') {
      $ta::Add('marshal', [Type][Runtime.InteropServices.Marshal])
    }
    #section characteristics
    $Sections = {param([UInt32]$i)
      (-join (($ht = @{
        'TypeReg'           = 0x00000000
        'TypeDesct'         = 0x00000001
        'TypeNoLoad'        = 0x00000002
        'TypeNoGroup'       = 0x00000004
        'TypeNoPadded'      = 0x00000008
        'TypeCopy'          = 0x00000010
        'Code'              = 0x00000020
        'InitializedData'   = 0x00000040
        'UninitializedData' = 0x00000080
        'LinkOther'         = 0x00000100
        'LinkInfo'          = 0x00000200
        'TypeOver'          = 0x00000400
        'LinkRemove'        = 0x00000800
        'LinkComDat'        = 0x00001000
        'Res0'              = 0x00002000
        'NoDeferSpecExc'    = 0x00004000
        'RelativeGP'        = 0x00008000
        'Res1'              = 0x00010000
        'MemPurgeable'      = 0x00020000
        'MemLocked'         = 0x00040000
        'MemPreload'        = 0x00080000
        'Align1Bytes'       = 0x00100000
        'Align2Bytes'       = 0x00200000
        'Align4Bytes'       = 0x00300000
        'Align8Bytes'       = 0x00400000
        'Align16Bytes'      = 0x00500000
        'Align32Bytes'      = 0x00600000
        'Align64Bytes'      = 0x00700000
        'Align128Bytes'     = 0x00800000
        'Align256Bytes'     = 0x00900000
        'Align512Bytes'     = 0x00A00000
        'Align1024Bytes'    = 0x00B00000
        'Align2048Bytes'    = 0x00C00000
        'Align4096Bytes'    = 0x00D00000
        'Align8192Bytes'    = 0x00E00000
        'AlignMask'         = 0x00F00000
        'LinkrelocOvflw'    = 0x01000000
        'MemDiscardable'    = 0x02000000
        'MemNotCached'      = 0x04000000
        'MemNotPaged'       = 0x08000000
        'MemShared'         = 0x10000000
        'MemExecute'        = 0x20000000
        'MemRead'           = 0x40000000
        'MemWrite'          = 0x80000000
      }).Keys | % {if ($i -band $ht[$_]) {$_ + '; '}})).Trim()
    }
  }
  process {
    try {
      $fs = [IO.File]::OpenRead($File)
      $br = New-Object IO.BinaryReader($fs)
      
      $e_magic = $br.ReadUInt16() -eq 23117 #MZ
      $fs.Position = 0x3C #e_lfamew
      $fs.Position = $br.ReadUInt32()
      $pe_sign = $br.ReadUInt32() -eq 17744 #PE00
      
      if (!$e_magic -or !$pe_sign) {
        throw (New-Object ArgumentException('Specified file is not valid PE.'))
      }
      
      $fs.Position += 0x14
      $Magic = $br.ReadUInt16() #PE\PE+ signature
      
      $fs.Position = 0 #move back and read whole file
      $buf = New-Object "Byte[]" $fs.Length
      [void]$fs.Read($buf, 0, $buf.Length)
      
      $gch = [Runtime.InteropServices.GCHandle]::Alloc($buf, 'Pinned')
      $ptr = $gch.AddrOfPinnedObject()
      #IMAGE_DOS_HEADER dump
      $IMAGE_DOS_HEADER = &$strc IMAGE_DOS_HEADER
      $IMAGE_DOS_HEADER = [Marshal]::PtrToStructure($ptr, $IMAGE_DOS_HEADER.GetType())
      #IMAGE_NT_HEADERS dump
      $nt_base = $NativeMethods.GetMethod('ImageNtHeader', (&$flag 40)).Invoke($null, @($ptr))
      $IMAGE_NT_HEADERS = switch ($Magic) { 0x10B { &$nthdr 32 } 0x20B { &$nthdr 64 } }
      $IMAGE_NT_HEADERS = [Marshal]::PtrToStructure($nt_base, $IMAGE_NT_HEADERS.GetType())
      #IMAGE_FILE_HEADER dump
      $IMAGE_FILE_HEADER = New-Object Object
      ($raw = &$field $IMAGE_NT_HEADERS fileHeader).GetType().GetFields((&$flag 36)) | % {
        $IMAGE_FILE_HEADER | Add-Member $_.Name -MemberType NoteProperty -Value $(
          $val = $_.GetValue($raw)
          switch ($_.Name) {
            'Machine'         { [Reflection.ImageFileMachine]$val }
            'TimeDateStamp'   {
              [TimeZone]::CurrentTimeZone.ToLocalTime(([DateTime]'1.1.1970').AddSeconds($val))
            }
            'Characteristics' {
               (-join (($ht = @{
                 'RelocsStripped'    = 0x0001
                 'Executable'        = 0x0002
                 'LineNumsStripped'  = 0x0004
                 'LocalSymsStripped' = 0x0008
                 'AggressiveWSTrim'  = 0x0010
                 'LargeAddressAware' = 0x0020
                 'Reserved'          = 0x0040
                 'BytesReservedLo'   = 0x0080
                 '32BitMachine'      = 0x0100
                 'DebugStripped'     = 0x0200
                 'RmvblRunFromSwap'  = 0x0400
                 'NetRunFromSwap'    = 0x0800
                 'System'            = 0x1000
                 'DLL'               = 0x2000
                 'UpSystemOnly'      = 0x4000
                 'BytesReseredHI'    = 0x8000
               }).Keys | % {
                 if (($val -band $ht[$_]) -eq $ht[$_]) {$_ + "`n"}
               })).Trim()
            }
            default           { $val }
          } #switch
        ) #value
      }
      #IMAGE_OPTIONAL_HEADER dump
      $IMAGE_OPTIONAL_HEADER = New-Object Object
      ($raw = &$field $IMAGE_NT_HEADERS optionalHeader).GetType().GetFields((&$flag 36)) | % {
        if ($_.Name -ne 'DataDirectory') {
          $IMAGE_OPTIONAL_HEADER | Add-Member $_.Name -MemberType NoteProperty -Value $(
            $val = $_.GetValue($raw)
            if ($_.Name -match 'Version') {
              $val
            }
            elseif ($_.Name -eq 'Subsystem') {
              (@{
                'Unknown'        = 0x00
                'Native'         = 0x01
                'WindowsGUI'     = 0x02
                'WindowsCUI'     = 0x03
                'POSIX_CUI'      = 0x07
                'WindowsCE_GUI'  = 0x09
                'EFIApplication' = 0x0A
                'EFIBootSrvDrv'  = 0x0B
                'EFIRuntimeDrv'  = 0x0C
                'EFIRom'         = 0x0D
                'XBox'           = 0x0E
              }.GetEnumerator() | ? {$_.Value -eq $val}).Name
            }
            elseif ($_.Name -eq 'DllCharacteristics') {
              (-join (($ht = @{
                'Reserved0'      = 0x0001
                'Reserved1'      = 0x0002
                'Reserved2'      = 0x0004
                'Reserved3'      = 0x0008
                'DynamicBase'    = 0x0040
                'ForceIntegrity' = 0x0080
                'NXCompatible'   = 0x0100
                'NoIsolation'    = 0x0200
                'NoSEH'          = 0x0400
                'NoBind'         = 0x0800
                'Reserved4'      = 0x1000
                'WDMDriver'      = 0x2000
                'TermSrvAware'   = 0x8000
              }).Keys | % {
                if (($val -band $ht[$_]) -eq $ht[$_]) {$_ + '; '}
              })).Trim()
            }
            else {
              '0x{0:X}' -f $val
            }
          ) #value
        }
      }
      #IMAGE_DATA_DIRECTORY[]
      [IntPtr]$rva_ptr = $nt_base.ToInt64() + [Marshal]::SizeOf($IMAGE_NT_HEADERS) - 128
      $IMAGE_DATA_DIRECTORY = 0..($IMAGE_OPTIONAL_HEADER.NumberOfRvaAndSizes - 1) | % {
        $dd = &$strc IMAGE_DATA_DIRECTORY
      }{
        [Marshal]::PtrToStructure($rva_ptr, $dd.GetType())
        [IntPtr]$rva_ptr = $rva_ptr.ToInt64() + 0x8
      }
      #IMAGE_SECTION_HEADER[]
      $IMAGE_SECTION_HEADER = 0..($IMAGE_FILE_HEADER.NumberOfSections - 1) | % {
        $sh = &$strc IMAGE_SECTION_HEADER
        $sec_ptr = $rva_ptr #first section pointer
      }{
        $sec = [Marshal]::PtrToStructure($sec_ptr, $sh.GetType())
        New-Object PSObject -Property @{
          Name             = [Text.Encoding]::Default.GetString($sec.Name)
          VirtualSize      = '0x{0:X}' -f $sec.VirtualSize
          VirtualAddress   = '0x{0:X}' -f $sec.VirtualAddress
          SizeOfRawData    = '0x{0:X}' -f $sec.SizeOfRawData
          PointerToRawData = '0x{0:X}' -f $sec.PointerToRawData
          Characteristics  = &$Sections $sec.Characteristics
        } | select Name, VirtualSize, VirtualAddress, SizeOfRawData, PointerToRawData, Characteristics
        [IntPtr]$sec_ptr = $sec_ptr.ToInt64() + 0x28
      } | ft -a
      #compile all in one
      $PEHeader = New-Object PSObject -Property @{
        DosHeader       = $IMAGE_DOS_HEADER
        FileHeader      = $IMAGE_FILE_HEADER
        OptionalHeader  = $IMAGE_OPTIONAL_HEADER
        DataDirectories = $IMAGE_DATA_DIRECTORY
        Sections        = $IMAGE_SECTION_HEADER
      }
      $PEHeader | select DosHeader, FileHeader, OptionalHeader, DataDirectories, Sections
    }
    catch {
      $_.Exception
    }
    finally {
      if ($gch -ne $null) { $gch.Free() }
      if ($br  -ne $null) { $br.Close() }
      if ($fs  -ne $null) { $fs.Close() }
    }
  }
  end {}
}
