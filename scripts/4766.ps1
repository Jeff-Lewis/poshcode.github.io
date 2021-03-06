#It seems very curios feature IsConsoleApplication defined in
#System.Management.Automation.NativeCommandProcessor class
#because it always returns True at text files and etc. but not
#on Windows application. Why?
#
#.method private hidebysig static bool  IsConsoleApplication(string fileName) cil managed
#{
#  ...
#  IL_0001:  call       bool System.Management.Automation.NativeCommandProcessor::IsWindowsApplication(string)
#  ...
#} // end of method NativeCommandProcessor::IsConsoleApplication
#
#It calls IsWindowsApplication method to test a file, so...
#
#.method private hidebysig static bool  IsWindowsApplication(string fileName) cil managed
#{
#  ...
#  IL_001c:  call       native int System.Management.Automation.NativeCommandProcessor::SHGetFileInfo(string,
#                                                                                                     uint32,
#                                                                                                     valuetype System.Management.Automation.NativeCommandProcessor/SHFILEINFO&,
#                                                                                                     uint32,
#                                                                                                     uint32)
#  ...
#} // end of method NativeCommandProcessor::IsWindowsApplication
#
#Isn't funny?
#I wrote a function that demonstrates IsConsoleApplication... hmmm, feature:)
function Test-Application {
  <#
    .EXAMPLE
        PS C:\>Test-Application E:\bin\whois.exe
        
        FileName         IsConApp IsWinApp
        --------         -------- --------
        E:\bin\whois.exe     True    False
        
        PS C:\>
  #>
  param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [ValidateScript({Test-Path $_})]
    [String]$FileName
  )
  
  begin {
    function get([String]$Method) {
      return [PSObject].Assembly.GetType(
        'System.Management.Automation.NativeCommandProcessor'
      ).GetMethod($Method, [Reflection.BindingFlags]'NonPublic, Static')
    }
    
    $IsConsoleApplication = get IsConsoleApplication
    $IsWindowsApplication = get IsWindowsApplication
  }
  process {
    $FileName = cvpa $FileName
    $str = '' | select FileName, IsConApp, IsWinApp
    $str.FileName = $FileName
    $str.IsConApp = $IsConsoleApplication.Invoke($null, @($FileName))
    $str.IsWinApp = $IsWindowsApplication.Invoke($null, @($FileName))
  }
  end {
    $str | ft -a
  }
}
