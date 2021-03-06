using System;
using System.Reflection;
using System.Runtime.InteropServices;

[assembly: AssemblyCompany("greg zakharov")]
[assembly: AssemblyCopyright("Copyright (C) 2014 greg zakharov")]
[assembly: AssemblyCulture("")]
[assembly: AssemblyDescription("System Up Time")]
[assembly: AssemblyTitle("uptime")]
[assembly: AssemblyVersion("1.0.0.0")]
[assembly: CLSCompliant(true)]

namespace SystemUptime {
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
  }
  
  [StructLayout(LayoutKind.Explicit, Size = 8)]
  internal struct LARGE_INTEGER {
    [FieldOffset(0)]
    public Int64  QuadPart;
    [FieldOffset(0)]
    public UInt32 LowPart;
    [FieldOffset(4)]
    public Int32  HighPart;
  }
  
  [StructLayout(LayoutKind.Sequential)]
  internal struct SYSTEM_TIME_INFORMATION {
    public LARGE_INTEGER liKeBootTime;
    public LARGE_INTEGER liKeSystemTime;
    public LARGE_INTEGER liKeExpTimeZoneBias;
    public UInt64 uCurrentTimeZoneId;
    public UInt32 dwRserved;
  }
  
  internal static class NativeMethods {
    [DllImport("ntdll.dll")]
    internal static extern Int32 NtQuerySystemInformation(
        UInt32 SystemInformationClass,
        out SYSTEM_TIME_INFORMATION SystemInformation,
        UInt32 SystemInformationLength,
        out UInt32 ReturnLength
    );
  }
  
  internal sealed class Program {
    static void Main() {
      SYSTEM_TIME_INFORMATION sti = new SYSTEM_TIME_INFORMATION();
      UInt32 ret = 0;
      DateTime now = DateTime.Now;
      
      if (NativeMethods.NtQuerySystemInformation(
          (UInt32)3, //SystemTimeInformation
          out sti,
          (UInt32)Marshal.SizeOf(sti),
          out ret
      ) < 0) {
        Console.WriteLine("NtQuerySystemInformation failed.");
        return;
      }
      
      AssemblyInfo ai = new AssemblyInfo();
      Console.WriteLine("{0} v{1} - {2}\n{3}\n", ai.Title, ai.Version, ai.Description, ai.Copyright);
      Console.WriteLine(now - DateTime.FromFileTime(sti.liKeBootTime.QuadPart));
    }
  } //Program
}
