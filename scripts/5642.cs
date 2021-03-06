using System;
using System.Text;
using System.Reflection;
using System.Text.RegularExpressions;
using System.Runtime.InteropServices;

[assembly: AssemblyCompany("greg zakharov")]
[assembly: AssemblyCopyright("Copyright (C) 2014 greg zakharov")]
[assembly: AssemblyCulture("")]
[assembly: AssemblyDescription("Loaded drivers viewer")]
[assembly: AssemblyTitle("drvlist")]
[assembly: AssemblyVersion("1.0.0.0")]
[assembly: CLSCompliant(true)]

namespace DriversList {
  internal sealed class AssemblyInfo {
    internal Type a;
    internal AssemblyInfo() { a = typeof(Program); }
    
    internal String Copyright {
      get {
        return ((AssemblyCopyrightAttribute)Attribute.GetCustomAttribute(
            a.Assembly, typeof(AssemblyCopyrightAttribute)
        )).Copyright;
      }
    }
    
    internal String Description {
      get {
        return ((AssemblyDescriptionAttribute)Attribute.GetCustomAttribute(
            a.Assembly, typeof(AssemblyDescriptionAttribute)
        )).Description;
      }
    }
    
    internal String Title {
      get {
        return ((AssemblyTitleAttribute)Attribute.GetCustomAttribute(
            a.Assembly, typeof(AssemblyTitleAttribute)
        )).Title;
      }
    }
    
    internal String Version {
      get { return a.Assembly.GetName().Version.ToString(2); }
    }
  } //AssemblyInfo
  
  internal sealed class Program {
    static IntPtr GetProcAddress(String dll, String fun) {
      Type UnsafeNativeMethods = Assembly
          .GetAssembly(typeof(Regex))
          .GetType("Microsoft.Win32.UnsafeNativeMethods");
      
      MethodInfo GetModuleHandle = UnsafeNativeMethods.GetMethod("GetModuleHandle");
      MethodInfo GetProcAddress  = UnsafeNativeMethods.GetMethod("GetProcAddress");
      
      HandleRef href = new HandleRef(
          new IntPtr(), (IntPtr)GetModuleHandle.Invoke(null, new Object[] {dll})
      );
      
      return (IntPtr)GetProcAddress.Invoke(null, new Object[] {href, fun});
    } //GetProcAddress
    
    static IntPtr LoadLibrary(String dll) {
      return (IntPtr)Assembly
          .GetAssembly(typeof(Regex))
          .GetType("Microsoft.Win32.SafeNativeMethods")
          .GetMethod("LoadLibrary")
          .Invoke(null, new Object[] {dll});
    } //LoadLibrary
    
    static Boolean FreeLibrary(IntPtr dll) {
      MethodInfo FreeLibrary = Assembly
          .GetAssembly(typeof(Regex))
          .GetType("Microsoft.Win32.SafeNativeMethods")
          .GetMethod("FreeLibrary");
      
      HandleRef href = new HandleRef(new IntPtr(), dll);
      
      return (Boolean)FreeLibrary.Invoke(null, new Object[] {href});
    } //FreeLibrary
    
    delegate Int32 GetDeviceDriverBaseNameDelegate(
        UInt32        ImageBase,
        StringBuilder lpBaseName,
        Int32         nSize
    );
    
    [return: MarshalAs(UnmanagedType.Bool)]
    delegate Boolean EnumDeviceDriversDelegate(
        [MarshalAs(UnmanagedType.LPArray, ArraySubType = UnmanagedType.U4)]
        [In][Out] UInt32[] lpImageBase,
        UInt32             cb,
        [MarshalAs(UnmanagedType.U4)]
        out UInt32         lpcbNeeded
    );
    
    static void Main() {
      IntPtr   ptr, module = IntPtr.Zero;
      Boolean  res;
      UInt32   BytesNeeded, ArraySize, SizeBytes;
      UInt32[] ImageBase;
      
      EnumDeviceDriversDelegate EnumDeviceDrivers;
      GetDeviceDriverBaseNameDelegate GetDeviceDriverBaseName;
      
      AssemblyInfo ai = new AssemblyInfo();
      Console.WriteLine("{0} v{1} - {2}\n{3}\n", ai.Title, ai.Version, ai.Description, ai.Copyright);
      //check PSAPI_VERSION
      if ((ptr = GetProcAddress("kernel32.dll", "EnumDeviceDrivers")) != IntPtr.Zero) {
        EnumDeviceDrivers =
            (EnumDeviceDriversDelegate)Marshal.GetDelegateForFunctionPointer(
                ptr, typeof(EnumDeviceDriversDelegate)
        );
        
        ptr = GetProcAddress("kernel32.dll", "GetDeviceDriverBaseNameA");
        GetDeviceDriverBaseName =
            (GetDeviceDriverBaseNameDelegate)Marshal.GetDelegateForFunctionPointer(
                ptr, typeof(GetDeviceDriverBaseNameDelegate)
        );
      }
      else {
        module = LoadLibrary("psapi.dll");
        
        ptr = GetProcAddress("psapi.dll", "EnumDeviceDrivers");
        EnumDeviceDrivers =
            (EnumDeviceDriversDelegate)Marshal.GetDelegateForFunctionPointer(
                ptr, typeof(EnumDeviceDriversDelegate)
        );
        
        ptr = GetProcAddress("psapi.dll", "GetDeviceDriverBaseNameA");
        GetDeviceDriverBaseName =
            (GetDeviceDriverBaseNameDelegate)Marshal.GetDelegateForFunctionPointer(
                ptr, typeof(GetDeviceDriverBaseNameDelegate)
        );
      }
      
      res = EnumDeviceDrivers(null, 0, out BytesNeeded);
      if (!res || BytesNeeded == 0) {
        Console.WriteLine("Could not enumerate drivers.");
        if (module != IntPtr.Zero) FreeLibrary(module);
        return;
      }
      
      ArraySize = BytesNeeded / 4;
      SizeBytes = BytesNeeded;
      ImageBase = new UInt32[ArraySize];
      
      if (!EnumDeviceDrivers(ImageBase, SizeBytes, out BytesNeeded)) {
        Console.WriteLine("EnumDeviceDrivers failed.");
        if (module != IntPtr.Zero) FreeLibrary(module);
        return;
      }
      
      Console.WriteLine("ImageBase  Driver\n{0}  {1}", new String('-', 9), new String('-', 7));
      StringBuilder sb = new StringBuilder(1000);
      for (Int32 i = 0; i < ArraySize; i++) {
        if (GetDeviceDriverBaseName(ImageBase[i], sb, sb.Capacity) != 0) {
          Console.WriteLine("0x{0:X8} {1}", (UInt32)ImageBase[i], sb.ToString());
        }
      }
      
      if (module != IntPtr.Zero) FreeLibrary(module);
    }
  } //Program
}
