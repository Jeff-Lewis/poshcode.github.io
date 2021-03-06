function Get-ProcAddress {
<#
.Synopsis
Returns the address of the desired Windows API function.

.Description
The Get-ProcAddress function returns the address of the desired Windows API
function. The technique used to get the address does not rely upon P/Invoke or
compiling C# code. GetProcAddress can be accessed through internal .NET methods
that are simply wrappers for native functions. The Microsoft.Win32.UnsafeNativeMethods
class exports GetProcAddress. This function indirectly access this internal class.

.Parameter Module
Specifies the module that exports the desired function

.Parameter Procedure
Specifies the name of the function whose address will be returned.

.Example
PS> Get-ProcAddress -Module kernel32.dll -Procedure LoadLibraryA
Description
-----------
Returns the address of LoadLibraryA in kernel32.dll.

.Outputs
System.IntPtr
Get-ProcAddress return the address of the function as an IntPtr. If the module or
function is not found, Get-ProcAddress will return [IntPtr]::Zero.

.Link
http://www.exploit-monday.com/
#>

Param (
    [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)] [String] $Module,
    [Parameter(Position = 1, Mandatory = $true)] [String] $Procedure
)

    # Get a reference to System.dll in the GAC
    $SystemAssembly = [AppDomain]::CurrentDomain.GetAssemblies() |
        Where-Object { $_.GlobalAssemblyCache -And $_.Location.Split('\\')[-1].Equals('System.dll') }
        
    $UnsafeNativeMethods = $SystemAssembly.GetType('Microsoft.Win32.UnsafeNativeMethods')
    
    # Get a reference to the GetModuleHandle and GetProcAddress methods
    $GetModuleHandle = $UnsafeNativeMethods.GetMethod('GetModuleHandle')
    $GetProcAddress = $UnsafeNativeMethods.GetMethod('GetProcAddress')
    # Get a handle to the module specified
    $Kern32Handle = $GetModuleHandle.Invoke($null, @($Module))
    
    $tmpPtr = New-Object IntPtr
    $HandleRef = New-Object System.Runtime.InteropServices.HandleRef($tmpPtr, $Kern32Handle)
    
    # Return the address of the function
    return $GetProcAddress.Invoke($null, @([System.Runtime.InteropServices.HandleRef]$HandleRef, $Procedure))
    
}
