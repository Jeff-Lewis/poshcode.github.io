using System;
using System.Diagnostics;
using System.ServiceProcess;
using System.ComponentModel;
using System.Configuration.Install;
using System.Management;
using System.Threading;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Runtime.InteropServices;
using System.Security.Permissions;
using System.Security.Principal;


namespace PriorityService
{

    
    public class PriorityService : ServiceBase
    {
        /// <summary>
        /// Public Constructor for WindowsService.
        /// - Put all of your Initialization code here.
        /// </summary>
        /// 
        
        public PriorityService()
        {            
            
            this.ServiceName = "PriorityService";
            this.EventLog.Log = "Application";

            // These Flags set whether or not to handle that specific
            //  type of event. Set to true if you need it, false otherwise.
            
            this.CanHandlePowerEvent = true;
            this.CanHandleSessionChangeEvent = true;
            this.CanPauseAndContinue = true;
            this.CanShutdown = true;
            this.CanStop = true;            
        }

        /// <summary>
        /// The Main Thread: This is where your Service is Run.
        /// </summary>
        static void Main()
        {
            ServiceBase.Run(new PriorityService());
            
        }

        /// <summary>
        /// Dispose of objects that need it here.
        /// </summary>
        /// <param name="disposing">Whether
        ///    or not disposing is going on.</param>
        protected override void Dispose(bool disposing)
        {
            base.Dispose(disposing);
        }


        
        /// <summary>
        /// OnStart(): Put startup code here
        ///  - Start threads, get inital data, etc.
        /// </summary>
        /// <param name="args"></param>
        protected override void OnStart(string[] args)
        {
            EventWatcherAsync.EventWatcherAsyncStart();
            base.OnStart(args);
        }

        /// <summary>
        /// OnStop(): Put your stop code here
        /// - Stop threads, set final data, etc.
        /// </summary>
        protected override void OnStop()
        {
            EventWatcherAsync.Watcher.Stop();
            base.OnStop();
        }

        /// <summary>
        /// OnPause: Put your pause code here
        /// - Pause working threads, etc.
        /// </summary>
        protected override void OnPause()
        {
            EventWatcherAsync.Watcher.Stop();
            base.OnPause();
        }

        /// <summary>
        /// OnContinue(): Put your continue code here
        /// - Un-pause working threads, etc.
        /// </summary>
        protected override void OnContinue()
        {
            EventWatcherAsync.EventWatcherAsyncStart();
            base.OnContinue();
        }

        /// <summary>
        /// OnShutdown(): Called when the System is shutting down
        /// - Put code here when you need special handling
        ///   of code that deals with a system shutdown, such
        ///   as saving special data before shutdown.
        /// </summary>
        protected override void OnShutdown()
        {
            EventWatcherAsync.Watcher.Stop();
            base.OnShutdown();
        }

        /// <summary>
        /// OnCustomCommand(): If you need to send a command to your
        ///   service without the need for Remoting or Sockets, use
        ///   this method to do custom methods.
        /// </summary>
        /// <param name="command">Arbitrary Integer between 128 & 256</param>
        protected override void OnCustomCommand(int command)
        {
            //  A custom command can be sent to a service by using this method:
            //#  int command = 128; //Some Arbitrary number between 128 & 256
            //#  ServiceController sc = new ServiceController("NameOfService");
            //#  sc.ExecuteCommand(command);

            base.OnCustomCommand(command);
        }

        /// <summary>
        /// OnPowerEvent(): Useful for detecting power status changes,
        ///   such as going into Suspend mode or Low Battery for laptops.
        /// </summary>
        /// <param name="powerStatus">The Power Broadcast Status
        /// (BatteryLow, Suspend, etc.)</param>
        protected override bool OnPowerEvent(PowerBroadcastStatus powerStatus)
        {
            return base.OnPowerEvent(powerStatus);
        }

        /// <summary>
        /// OnSessionChange(): To handle a change event
        ///   from a Terminal Server session.
        ///   Useful if you need to determine
        ///   when a user logs in remotely or logs off,
        ///   or when someone logs into the console.
        /// </summary>
        /// <param name="changeDescription">The Session Change
        /// Event that occured.</param>
        protected override void OnSessionChange(
                  SessionChangeDescription changeDescription)
        {
            base.OnSessionChange(changeDescription);            
        }
    }

    [RunInstaller(true)]
    public class WindowsServiceInstaller : Installer
    {
        /// <summary>
        /// Public Constructor for WindowsServiceInstaller.
        /// - Put all of your Initialization code here.
        /// </summary>
        public WindowsServiceInstaller()
        {
            ServiceProcessInstaller serviceProcessInstaller =
                               new ServiceProcessInstaller();
            ServiceInstaller serviceInstaller = new ServiceInstaller();

            //# Service Account Information
                
            serviceProcessInstaller.Account = ServiceAccount.LocalSystem;
            serviceProcessInstaller.Username = null;
            serviceProcessInstaller.Password = null;

            //# Service Information
            serviceInstaller.DisplayName = "Service to manage priorities";
            serviceInstaller.StartType = ServiceStartMode.Automatic;
            

            //# This must be identical to the WindowsService.ServiceBase name
            //# set in the constructor of WindowsService.cs
            serviceInstaller.ServiceName = "PriorityService";
            serviceInstaller.DelayedAutoStart = true;
            serviceInstaller.ServicesDependedOn = new string[] {"Windows Management Instrumentation"};

            serviceInstaller.Parent = this;
            serviceProcessInstaller.Parent = this;
            
            this.Installers.Add(serviceProcessInstaller);
            this.Installers.Add(serviceInstaller);
            this.Committed+=new InstallEventHandler(ServiceInstaller_Committed);
            


        }


        void ServiceInstaller_Committed(object sender, InstallEventArgs e)
        {
            using (var controller = new ServiceController("PriorityService"))
            {
                controller.Start();
                controller.WaitForStatus(ServiceControllerStatus.Running);
            }
        }
    }

    
    public static class EventWatcherAsync
    {
        public static void WmiEventHandler(object sender, EventArrivedEventArgs e)
        {
            //in this point the new events arrives
            //you can access to any property of the Win32_Process class
            //Console.WriteLine("TargetInstance.Handle :    " + ((ManagementBaseObject)e.NewEvent.Properties["TargetInstance"].Value)["Handle"]);
            //Console.WriteLine("TargetInstance.Name :      " + ((ManagementBaseObject)e.NewEvent.Properties["TargetInstance"].Value)["Name"]);
            int pid;
            string name = ((ManagementBaseObject)e.NewEvent.Properties["TargetInstance"].Value)["Name"].ToString().ToLower();

            if (name.StartsWith("mpc-hc64"))
            {
                pid = Convert.ToInt32(((ManagementBaseObject)e.NewEvent.Properties["TargetInstance"].Value)["ProcessId"].ToString());
                change_priority.change_prio(pid, change_priority.realtime, 4);
            }
            if (name.StartsWith("foobar"))
            {
                pid = Convert.ToInt32(((ManagementBaseObject)e.NewEvent.Properties["TargetInstance"].Value)["ProcessId"].ToString());
                change_priority.change_prio(pid, change_priority.realtime, 4);
            }
            if (name.StartsWith("iexplore"))
            {
                pid = Convert.ToInt32(((ManagementBaseObject)e.NewEvent.Properties["TargetInstance"].Value)["ProcessId"].ToString());
                change_priority.change_prio(pid, change_priority.high, 4);
            }
            if (name.StartsWith("robocopy"))
            {
                pid = Convert.ToInt32(((ManagementBaseObject)e.NewEvent.Properties["TargetInstance"].Value)["ProcessId"].ToString());
                change_priority.change_prio(pid, change_priority.idle, 1);
            }
        }

        public static ManagementEventWatcher Watcher;
        public static void EventWatcherAsyncStart()
        {
            try
            {
                string ComputerName = "localhost";
                string WmiQuery;                
                ManagementScope Scope;

                Scope = new ManagementScope(String.Format("\\\\{0}\\root\\CIMV2", ComputerName), null);
                Scope.Connect();

                WmiQuery = "Select * From __InstanceCreationEvent Within 1 " +
                "Where TargetInstance ISA 'Win32_Process' ";

                Watcher = new ManagementEventWatcher(Scope, new EventQuery(WmiQuery));
                Watcher.EventArrived += new EventArrivedEventHandler(WmiEventHandler);
                Watcher.Start();
                //Console.Read();
                //Watcher.Stop();
            }
            catch (Exception e)
            {
                //Console.WriteLine("Exception {0} Trace {1}", e.Message, e.StackTrace);
            }

        }

    }

    class change_priority
    {
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public struct STARTUPINFO
        {
            public Int32 cb;
            public string lpReserved;
            public string lpDesktop;
            public string lpTitle;
            public Int32 dwX;
            public Int32 dwY;
            public Int32 dwXSize;
            public Int32 dwYSize;
            public Int32 dwXCountChars;
            public Int32 dwYCountChars;
            public Int32 dwFillAttribute;
            public Int32 dwFlags;
            public Int16 wShowWindow;
            public Int16 cbReserved2;
            public IntPtr lpReserved2;
            public IntPtr hStdInput;
            public IntPtr hStdOutput;
            public IntPtr hStdError;
        }

        [StructLayout(LayoutKind.Sequential)]
        internal struct PROCESS_INFORMATION
        {
            public IntPtr hProcess;
            public IntPtr hThread;
            public int dwProcessId;
            public int dwThreadId;
        }

        [StructLayout(LayoutKind.Sequential)]
        public class SECURITY_ATTRIBUTES
        {
            public int nLength;
            public unsafe byte* lpSecurityDescriptor;
            public int bInheritHandle;
        }

        public enum PROCESS_INFORMATION_CLASS : int
        {
            ProcessBasicInformation = 0,
            ProcessQuotaLimits,
            ProcessIoCounters,
            ProcessVmCounters,
            ProcessTimes,
            ProcessBasePriority,
            ProcessRaisePriority,
            ProcessDebugPort,
            ProcessExceptionPort,
            ProcessAccessToken,
            ProcessLdtInformation,
            ProcessLdtSize,
            ProcessDefaultHardErrorMode,
            ProcessIoPortHandlers,
            ProcessPooledUsageAndLimits,
            ProcessWorkingSetWatch,
            ProcessUserModeIOPL,
            ProcessEnableAlignmentFaultFixup,
            ProcessPriorityClass,
            ProcessWx86Information,
            ProcessHandleCount,
            ProcessAffinityMask,
            ProcessPriorityBoost,
            ProcessDeviceMap,
            ProcessSessionInformation,
            ProcessForegroundInformation,
            ProcessWow64Information,
            ProcessImageFileName,
            ProcessLUIDDeviceMapsEnabled,
            ProcessBreakOnTermination,
            ProcessDebugObjectHandle,
            ProcessDebugFlags,
            ProcessHandleTracing,
            ProcessIoPriority,
            ProcessExecuteFlags,
            ProcessResourceManagement,
            ProcessCookie,
            ProcessImageInformation,
            ProcessCycleTime,
            ProcessPagePriority,
            ProcessInstrumentationCallback,
            ProcessThreadStackAllocation,
            ProcessWorkingSetWatchEx,
            ProcessImageFileNameWin32,
            ProcessImageFileMapping,
            ProcessAffinityUpdateMode,
            ProcessMemoryAllocationMode,
            MaxProcessInfoClass
        }

        public enum STANDARD_RIGHTS : uint
        {
            WRITE_OWNER = 524288,
            WRITE_DAC = 262144,
            READ_CONTROL = 131072,
            DELETE = 65536,
            SYNCHRONIZE = 1048576,
            STANDARD_RIGHTS_REQUIRED = 983040,
            STANDARD_RIGHTS_WRITE = READ_CONTROL,
            STANDARD_RIGHTS_EXECUTE = READ_CONTROL,
            STANDARD_RIGHTS_READ = READ_CONTROL,
            STANDARD_RIGHTS_ALL = 2031616,
            SPECIFIC_RIGHTS_ALL = 65535,
            ACCESS_SYSTEM_SECURITY = 16777216,
            MAXIMUM_ALLOWED = 33554432,
            GENERIC_WRITE = 1073741824,
            GENERIC_EXECUTE = 536870912,
            GENERIC_READ = UInt16.MaxValue,
            GENERIC_ALL = 268435456
        }

        public enum PROCESS_RIGHTS : uint
        {
            PROCESS_TERMINATE = 1,
            PROCESS_CREATE_THREAD = 2,
            PROCESS_SET_SESSIONID = 4,
            PROCESS_VM_OPERATION = 8,
            PROCESS_VM_READ = 16,
            PROCESS_VM_WRITE = 32,
            PROCESS_DUP_HANDLE = 64,
            PROCESS_CREATE_PROCESS = 128,
            PROCESS_SET_QUOTA = 256,
            PROCESS_SET_INFORMATION = 512,
            PROCESS_QUERY_INFORMATION = 1024,
            PROCESS_SUSPEND_RESUME = 2048,
            PROCESS_QUERY_LIMITED_INFORMATION = 4096,
            PROCESS_ALL_ACCESS = STANDARD_RIGHTS.STANDARD_RIGHTS_REQUIRED | STANDARD_RIGHTS.SYNCHRONIZE | 65535
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct PROCESS_BASIC_INFORMATION
        {
            public int ExitStatus;
            public int PebBaseAddress;
            public int AffinityMask;
            public int BasePriority;
            public int UniqueProcessId;
            public int InheritedFromUniqueProcessId;
            public int Size
            {
                get { return (6 * 4); }
            }
        };


        [DllImport("kernel32.dll")]
        public static extern bool CreateProcess(
            string lpApplicationName,
            string lpCommandLine,
            ref SECURITY_ATTRIBUTES lpProcessAttributes,
            ref SECURITY_ATTRIBUTES lpThreadAttributes,
            bool bInheritHandles,
            uint dwCreationFlags,
            IntPtr lpEnvironment,
            string lpCurrentDirectory,
            [In] ref STARTUPINFO lpStartupInfo,
            out PROCESS_INFORMATION lpProcessInformation);

        [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public static extern bool SetPriorityClass(IntPtr handle, uint priorityClass);

        [DllImport("KERNEL32.DLL")]
        public static extern int
            OpenProcess(PROCESS_RIGHTS dwDesiredAccess, bool bInheritHandle, int
            dwProcessId);       

        [DllImport("ntdll.dll", SetLastError = true)]
        public static extern int NtSetInformationProcess(int processHandle,
           PROCESS_INFORMATION_CLASS processInformationClass, IntPtr processInformation, uint processInformationLength);

        [DllImport("ntdll.dll", SetLastError = true)]
        public static extern int NtQueryInformationProcess(int processHandle,
           PROCESS_INFORMATION_CLASS processInformationClass, IntPtr processInformation, int processInformationLength,
           ref int returnLength);

        public const int idle = 0;
        public const int high = 2;
        public const int realtime = 3;
        unsafe public static void change_prio(int pid, int prio, int ioPrio)
        {
            Process myproc = Process.GetProcessById(pid);
            switch (prio)
            {
                case high:
                    myproc.PriorityClass = System.Diagnostics.ProcessPriorityClass.High;
                    break;
                case realtime:
                    myproc.PriorityClass = System.Diagnostics.ProcessPriorityClass.RealTime;
                    break;
                case idle:
                    myproc.PriorityClass = System.Diagnostics.ProcessPriorityClass.Idle;
                    break;
            }

            int hProcess = OpenProcess(PROCESS_RIGHTS.PROCESS_ALL_ACCESS, false, pid);
            if (hProcess == 0)
            {
                throw new Exception("can't open the process.");
            }
            NtSetInformationProcess(hProcess, PROCESS_INFORMATION_CLASS.ProcessIoPriority,
                 (IntPtr)(&ioPrio), 4);
            //foreach (ProcessThread thread in myproc.Threads)
            //{
            //    thread.Id;
            //}
        }
    }

}
