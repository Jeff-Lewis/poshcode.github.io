#requires -version 2.0
<#
  .NOTES
      Author: greg zakharov
#>
Add-Type @'
using System;
using System.Text;
using System.Reflection;
using System.Runtime.InteropServices;

[assembly: AssemblyVersion("2.0.0.0")]

namespace DevDrivers {
  internal static class NativeMethods {
    [DllImport("psapi.dll", CharSet = CharSet.Unicode)]
    internal static extern Int32 GetDeviceDriverBaseName(
        UIntPtr ImageBase,
        StringBuilder lpBaseName,
        Int32 nSize
    );
    
    [DllImport("psapi.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    internal static extern Boolean EnumDeviceDrivers(
        [MarshalAs(UnmanagedType.LPArray, ArraySubType = UnmanagedType.U4)] [In][Out] UIntPtr[] lpImageBase,
        UInt32 cb,
        [MarshalAs(UnmanagedType.U4)] out UInt32 lpcbNeeded
    );
    
    internal static void GetDriversList() {
      Boolean  res;
      UInt32   BytesNeeded, ArraySize, SizeBytes;
      UIntPtr[] ImageBase;
      
      res = EnumDeviceDrivers(null, 0, out BytesNeeded);
      if (!res || BytesNeeded == 0) {
        Console.WriteLine("Can not enumerate drivers.");
        return;
      }
      
      ArraySize = BytesNeeded / 4;
      SizeBytes = BytesNeeded;
      ImageBase = new UIntPtr[ArraySize];
      
      res = EnumDeviceDrivers(ImageBase, SizeBytes, out BytesNeeded);
      if (!res) {
        Console.WriteLine("EnumDeviceDrivers is failed.");
        return;
      }
      
      Console.WriteLine("ImageBase  Driver\n{0} {1}", new String('-', 10), new String('-', 13));
      StringBuilder sb = new StringBuilder(1000);
      for (Int32 i = 0; i < ArraySize; i++) {
        if (GetDeviceDriverBaseName(ImageBase[i], sb, sb.Capacity) != 0)
          Console.WriteLine("0x{0:X8} {1}", (UInt32)ImageBase[i], sb.ToString());
      } //for
    }
  }
  
  public sealed class LoadedList {
    public static void Get() {
      NativeMethods.GetDriversList();
    }
  }
}
'@
[DevDrivers.LoadedList]::Get()
''
