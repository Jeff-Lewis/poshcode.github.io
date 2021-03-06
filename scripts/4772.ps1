$script:library = @'
using System;
using System.Reflection;
using System.Runtime.InteropServices;

[assembly: AssemblyVersion("2.0.0.0")]
[assembly: CLSCompliant(true)]
[assembly: ComVisible(false)]

namespace PEUtils {
  public sealed class Header {
    private Header() {}
    
    [Flags]
    internal enum IMAGE_FILE_MACHINE : ushort { //UInt16
      UNKNOWN   = 0,
      I386      = 0x014c,
      R3000     = 0x0162,
      R4000     = 0x0166,
      R10000    = 0x0168,
      WCEMIPSV2 = 0x0169,
      ALPHA     = 0x0184,
      SH3       = 0x01a2,
      SH3DSP    = 0x01a3,
      SH3E      = 0x01a4,
      SH4       = 0x01a6,
      SH5       = 0x01a8,
      ARM       = 0x01c0,
      THUMB     = 0x01c2,
      ARMNT     = 0x01c4,
      AM33      = 0x01d3,
      POWERPC   = 0x01f0,
      POWERPCFP = 0x01f1,
      IA64      = 0x0200,
      MIPS16    = 0x0266,
      ALPHA64   = 0x0284,
      MIPSFPU   = 0x0366,
      MIPSFPU16 = 0x0466,
      TRICORE   = 0x0520,
      CEF       = 0x0cef,
      EBC       = 0x0ebc,
      AMD64     = 0x8664,
      M32R      = 0x9041,
      CEE       = 0xc0ee
    }
    
    [Flags]
    internal enum IMAGE_FILE_CHARACTERISTICS : ushort { //UInt16
      RelocInfoStrippedFromFile     = 0x0001,
      Executable                    = 0x0002,
      LineNumbersStripped           = 0x0004,
      SymbolTableStripped           = 0x0008,
      AgressiveTrimWorkingSet       = 0x0010,
      LargeAddressAware             = 0x0020,
      Supports16Bit                 = 0x0040,
      ReservedBytesWo               = 0x0080,
      Supports32Bit                 = 0x0100,
      DebugInfoStripped             = 0x0200,
      RunFromSwapIfInRemovableMedia = 0x0400,
      RunFromSwapIfInNetworkMedia   = 0x0800,
      SystemFile                    = 0x1000,
      Dll                           = 0x2000,
      OnlyForSingleCoreProcessor    = 0x4000,
      BytesOfWordReserved           = 0x8000
    }
    
    [Flags]
    internal enum IMAGE_SUBSYSTEM : ushort { //UInt16
      UNKNOWN                  = 0,
      NATIVE                   = 1,
      WINDOWS_GUI              = 2,
      WINDOWS_CUI              = 3,
      OS2_CUI                  = 5,
      POSIX_CUI                = 7,
      NATIVE_WINDOWS           = 8,
      WINDOWS_CE_GUI           = 9,
      EFI_APPLICATION          = 10,
      EFI_BOOT_SERVICE_DRIVER  = 11,
      EFI_RUNTIME_DRIVER       = 12,
      EFI_ROM                  = 13,
      XBOX                     = 14,
      WINDOWS_BOOT_APPLICATION = 16
    }
    
    [Flags]
    internal enum IMAGE_DLLCHARACTERISTICS : ushort { //UInt16
      RES_0                 = 0x0001,
      RES_1                 = 0x0002,
      RES_2                 = 0x0004,
      RES_3                 = 0x0008,
      DYNAMIC_BASE          = 0x0040,
      FORCE_INTEGRITY       = 0x0080,
      NX_COMPAT             = 0x0100,
      NO_ISOLATION          = 0x0200,
      NO_SEH                = 0x0400,
      NO_BIND               = 0x0800,
      RES_4                 = 0x1000,
      WDM_DRIVER            = 0x2000,
      TERMINAL_SERVER_AWARE = 0x8000
    }
    
    [Flags]
    internal enum IMAGE_SECTIONCHARACTERISTICS : uint { //UInt32
      TypeReg                  = 0x00000000,
      TypeDsect                = 0x00000001,
      TypeNoLoad               = 0x00000002,
      TypeGroup                = 0x00000004,  
      TypeNoPadded             = 0x00000008,
      TypeCopy                 = 0x00000010,
      ContentCode              = 0x00000020,
      ContentInitializedData   = 0x00000040,
      ContentUninitializedData = 0x00000080,
      LinkOther                = 0x00000100,
      LinkInfo                 = 0x00000200,
      TypeOver                 = 0x00000400,
      LinkRemove               = 0x00000800,
      LinkComDat               = 0x00001000,
      NoDeferSpecExceptions    = 0x00004000,
      RelativeGP               = 0x00008000,
      MemPurgeable             = 0x00020000,
      Memory16Bit              = 0x00020000,
      MemoryLocked             = 0x00040000,
      MemoryPreload            = 0x00080000,
      Align1Bytes              = 0x00100000,
      Align2Bytes              = 0x00200000,
      Align4Bytes              = 0x00300000,
      Align8Bytes              = 0x00400000,
      Align16Bytes             = 0x00500000,
      Align32Bytes             = 0x00600000,
      Align64Bytes             = 0x00700000,
      Align128Bytes            = 0x00800000,
      Align256Bytes            = 0x00900000,
      Align512Bytes            = 0x00A00000,
      Align1024Bytes           = 0x00B00000,
      Align2048Bytes           = 0x00C00000,
      Align4096Bytes           = 0x00D00000,
      Align8192Bytes           = 0x00E00000,
      AlignMask                = 0x00F00000,
      LinkExRelocationOverflow = 0x01000000,
      MemoryDiscardable        = 0x02000000,
      MemoryNotCached          = 0x04000000,
      MemoryNotPaged           = 0x08000000,
      MemoryShared             = 0x10000000,
      MemoryExecute            = 0x20000000,
      MemoryRead               = 0x40000000,
      MemoryWrite              = 0x80000000 
    }
    
    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    internal struct IMAGE_DATA_DIRECTORY {
      public UInt32 VirtualAddress;
      public UInt32 Size;
    }
    
    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    internal struct IMAGE_DOS_HEADER {
      public UInt16 e_magic;
      public UInt16 e_cblp;
      public UInt16 e_cp;
      public UInt16 e_crlc;
      public UInt16 e_cparhdr;
      public UInt16 e_minalloc;
      public UInt16 e_maxalloc;
      public UInt16 e_ss;
      public UInt16 e_sp;
      public UInt16 e_csum;
      public UInt16 e_ip;
      public UInt16 e_cs;
      public UInt16 e_lfarlc;
      public UInt16 e_ovno;
      [MarshalAs(UnmanagedType.ByValArray, SizeConst = 4)]
      public UInt16[] e_res;
      public UInt16 e_oemid;
      public UInt16 e_oeminfo;
      [MarshalAs(UnmanagedType.ByValArray, SizeConst = 10)]
      public UInt16[] e_res2;
      public UInt32 e_lfanew;
    }
    
    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    internal struct IMAGE_FILE_HEADER {
      public IMAGE_FILE_MACHINE Machine;
      public UInt16 NumberOfSections;
      public UInt32 TimeDateStamp;
      public UInt32 PointerToSymbolTable;
      public UInt32 NumberOfSymbols;
      public UInt16 SizeOfOptionalHeader;
      public IMAGE_FILE_CHARACTERISTICS Characteristics;
    }
    
    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    internal struct IMAGE_OPTIONAL_HEADER32 {
      public UInt16 Magic;
      public Byte MajorLinkerVersion;
      public Byte MinorLinkerVersion;
      public UInt32 SizeOfCode;
      public UInt32 SizeOfInitializedData;
      public UInt32 SizeOfUninitializedData;
      public UInt32 AddressOfEntryPoint;
      public UInt32 BaseOfCode;
      public UInt32 BaseOfData;
      public UInt32 ImageBase;
      public UInt32 SectionAlignment;
      public UInt32 FileAlignment;
      public UInt16 MajorOperationSystemVersion;
      public UInt16 MinorOperationSystemVersion;
      public UInt16 MajorImageVersion;
      public UInt16 MinorImageVersion;
      public UInt16 MajorSubsystemVersion;
      public UInt16 MinorSybsystemVersion;
      public UInt32 Win32VersionValue;
      public UInt32 SizeOfImage;
      public UInt32 SizeOfHeaders;
      public UInt32 CheckSum;
      public IMAGE_SUBSYSTEM Subsystem;
      public IMAGE_DLLCHARACTERISTICS DllCharacteristics;
      public UInt32 SizeOfStackReserve;
      public UInt32 SizeOfStackCommit;
      public UInt32 SizeOfHeapReserve;
      public UInt32 SizeOfHeapCommit;
      public UInt32 LoaderFlags;
      public UInt32 NumberOfRvaAndSizes;
      [MarshalAsAttribute(UnmanagedType.ByValArray, SizeConst = 16)]
      public IMAGE_DATA_DIRECTORY[] DataDirectory;
    }
    
    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    internal struct IMAGE_OPTIONAL_HEADER64 {
      public UInt16 Magic;
      public Byte MajorLinkerVersion;
      public Byte MinorLinkerVersion;
      public UInt32 SizeOfCode;
      public UInt32 SizeOfInitializedData;
      public UInt32 SizeOfUninitializedData;
      public UInt32 AddressOfEntryPoint;
      public UInt32 BaseOfCode;
      public UInt64 ImageBase;
      public UInt32 SectionAlignment;
      public UInt32 FileAlignment;
      public UInt16 MajorOperatingSystemVersion;
      public UInt16 MinorOperatingSystemVersion;
      public UInt16 MajorImageVersion;
      public UInt16 MinorImageVersion;
      public UInt16 MajorSubsystemVersion;
      public UInt16 MinorSubsystemVersion;
      public UInt32 Win32VersionValue;
      public UInt32 SizeOfImage;
      public UInt32 SizeOfHeaders;
      public UInt32 CheckSum;
      public IMAGE_SUBSYSTEM Subsystem;
      public IMAGE_DLLCHARACTERISTICS DllCharacteristics;
      public UInt64 SizeOfStackReserve;
      public UInt64 SizeOfStackCommit;
      public UInt64 SizeOfHeapReserve;
      public UInt64 SizeOfHeapCommit;
      public UInt32 LoaderFlags;
      public UInt32 NumberOfRvaAndSizes;
      [MarshalAsAttribute(UnmanagedType.ByValArray, SizeConst=16)]
      public IMAGE_DATA_DIRECTORY[] DataDirectory;
    }
    
    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    internal struct IMAGE_SECTION_HEADER {
      [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 8)]
      public String Name;
      public UInt32 VirtualSize;
      public UInt32 VirtualAddress;
      public UInt32 SizeOfRawData;
      public UInt32 PointerToRawData;
      public UInt32 PointerToRelocations;
      public UInt32 PointerToLinenumbers;
      public UInt16 NumberOfRelocations;
      public UInt16 NumberOfLinenumbers;
      public IMAGE_SECTIONCHARACTERISTICS Characteristics;
    }
  }
}
'@

function Get-PEHeader {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [String]$FileName
  )
  
  begin {
    try {[void][PEUtils.Header]} catch [Management.Automation.RuntimeException] {
      $cscp = New-Object Microsoft.CSharp.CSharpCodeProvider
      
      $cp = New-Object CodeDom.Compiler.CompilerParameters
      $cp.GenerateExecutable = $false
      $cp.GenerateInMemory   = $true
      
      [void]$cscp.CompileAssemblyFromSource($cp, $library)
    }
    
    function Get-Struct([Object]$Base, [String]$Name) {
      return [Activator]::CreateInstance(
        $Base.GetNestedType($Name, [Reflection.BindingFlags]32)
      )
    }
    
    function Trace-Binary([IO.BinaryReader]$Reader, [Object]$Data) {
      $bytes = $Reader.ReadBytes(
        [Runtime.InteropServices.Marshal]::SizeOf($Data)
      )
      $hndl = [Runtime.InteropServices.GCHandle]::Alloc(
        $bytes, [Runtime.InteropServices.GCHandleType]::Pinned
      )
      $struct = [Runtime.InteropServices.Marshal]::PtrToStructure(
        $hndl.AddrOfPinnedObject(), $Data.GetType()
      )
      $hndl.Free()
      
      return $struct
    }
    
    function Trace-Stamp([Object]$Stamp) {
      return [TimeZone]::CurrentTimeZone.ToLocalTime(
        ([DateTime]'1.1.1970').AddSeconds($Stamp)
      )
    }
    
    $FileName = cvpa $FileName
    $nul = '-' * 35
    $asm = 'PEUtils.Header' -as [Type]
    
    $IMAGE_DOS_HEADER        = Get-Struct $asm IMAGE_DOS_HEADER
    $IMAGE_FILE_HEADER       = Get-Struct $asm IMAGE_FILE_HEADER
    $IMAGE_OPTIONAL_HEADER32 = Get-Struct $asm IMAGE_OPTIONAL_HEADER32
    $IMAGE_OPTIONAL_HEADER64 = Get-Struct $asm IMAGE_OPTIONAL_HEADER64
    $IMAGE_SECTION_HEADER    = Get-Struct $asm IMAGE_SECTION_HEADER
  }
  process {
    try {
      $fs = New-Object IO.FileStream($FileName, [IO.FileMode]::Open, [IO.FileAccess]::Read)
      $br = New-Object IO.BinaryReader($fs)
      
      $dos = Trace-Binary $br $IMAGE_DOS_HEADER
      [void]$fs.Seek($dos.e_lfanew, [IO.SeekOrigin]::Begin)
      $sig = $br.ReadUInt32()
      
      $fh = Trace-Binary $br $IMAGE_FILE_HEADER
      if ($fh.Characteristics.ToString().Split(', ') -contains 'Supports32Bit') {
        $pe = Trace-Binary $br $IMAGE_OPTIONAL_HEADER32
      }
      else {
        $pe = Trace-Binary $br $IMAGE_OPTIONAL_HEADER64
      }
      
      $sec = New-Object "$IMAGE_SECTION_HEADER[]" $fh.NumberOfSections
      for ($i = 0; $i -lt $sec.Length; ++$i) {
        $sec[$i] = Trace-Binary $br $IMAGE_SECTION_HEADER
      }
    }
    catch {$exp = [Boolean]$_.Exception}
    finally {
      if ($br -ne $null) {$br.Close()}
      if ($fs -ne $null) {$fs.Close()}
    }
  }
  end {
    switch ($exp) {
      $true {Write-Host Invalid PE file.`n -fo Red}
      default {
        "FILE HEADER VALUES`n$nul"
        $fh.PSObject.Properties | % {
          if ($_.Name -eq 'TimeDateStamp') {
            '{0, 21}: {1}' -f $_.Name, (Trace-Stamp $_.Value)
          }
          else {
            '{0, 21}: {1}' -f $_.Name, $_.Value
          }
        }
        "`n`nOPTIONAL HEADER VALUES`n$nul"
        $pe.PSObject.Properties | % {
          if ($_.Name -eq 'Magic') {
            '{0, 28}: {1}' -f $_.Name, $(if ($_.Value -eq 0x10b) {'PE32'} else {'PE32+'})
          }
          elseif ($_.Name -ne 'Subsystem' -and $_.Name -ne `
            'DllCharacteristics' -and $_.Name -ne 'MajorLinkerVersion') {
            '{0, 28}: {1:X}' -f $_.Name, $_.Value
          }
          else {
            '{0, 28}: {1}' -f $_.Name, $_.Value
          }
        }
        ""
        $sec | select Name, VirtualSize, VirtualAddress, SizeOfRawData, `
          PointerToRawData, Characteristics | ft -a
      }
    }
  }
}
