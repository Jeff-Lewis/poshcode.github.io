Set-StrictMode -Version 2

function Get-DelegateType {
<#
.Synopsis
Declares a non-generic delegate type for the method signature provided.

.Description
The Get-DelegateType function is the equivalent to declaring a delegate type in C#
with the 'delegate' keyword. PowerShell has no such equivalent, hence this
function.

This function was created in order to provide GetDelegateForFunctionPointer a
non-generic delegate.

.Parameter Parameters
Specifies the parameters of the desired method signature.

.Parameter ReturnType
Specifies the return type of the desired method signature.

.Example
PS> Get-DelegateType -Parameters @([String]) -ReturnType ([IntPtr])
Description
-----------
Returns a delegate type whose method signature contains a string as its parameter
and an IntPtr as a return type. What Get-DelegateType returns is the equivalent to
the following C# declaration:

public IntPtr MyDelegateType(String str);

.Example
PS> Get-DelegateType @([String], [Int])
Description
-----------
Returns a delegate type whose method signature contains a string and an int as its
parameter and an a Void return type.

.Outputs
System.MulticastDelegate
Get-DelegateType returns a System.MulticastDelegate derived delegate based upon the
provided method signature.

.Link
http://www.exploit-monday.com/
http://blogs.msdn.com/b/joelpob/archive/2004/02/15/73239.aspx
#>

Param (
    [Parameter(Position = 0, Mandatory = $True)] [Type[]] $Parameters,
    [Parameter(Position = 1)] [Type] $ReturnType = [Void]
)

    $Domain = [AppDomain]::CurrentDomain
    $DynAssembly = New-Object System.Reflection.AssemblyName('ReflectedDelegate')
    $AssemblyBuilder = $Domain.DefineDynamicAssembly($DynAssembly, [System.Reflection.Emit.AssemblyBuilderAccess]::Run)
    $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule('InMemoryModule', $false)
    $TypeBuilder = $ModuleBuilder.DefineType('MyDelegateType', 'Class, Public, Sealed, AnsiClass, AutoClass', [System.MulticastDelegate])
    $ConstructorBuilder = $TypeBuilder.DefineConstructor('RTSpecialName, HideBySig, Public', [System.Reflection.CallingConventions]::Standard, $Parameters)
    $ConstructorBuilder.SetImplementationFlags('Runtime, Managed')
    $MethodBuilder = $TypeBuilder.DefineMethod('Invoke', 'Public, HideBySig, NewSlot, Virtual', $ReturnType, $Parameters)
    $MethodBuilder.SetImplementationFlags('Runtime, Managed')
    return $TypeBuilder.CreateType()

}
