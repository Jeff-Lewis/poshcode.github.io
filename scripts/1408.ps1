function New-PInvoke
{
    <#
    .Synopsis
        Generate a powershell function alias to a Win32|C api function
    .Description
        Creates C# code to access a C function, and exposes it via a powershell function
    .Example
        New-PInvoke -Library User32.dll -Signature "int GetSystemMetrics(uint Metric)"
    .Parameter Library
        A C Library containing code to invoke
    .Parameter Signature
        The C# signature of the external method
    .Parameter OutputText
        If Set, retuns the source code for the pinvoke method.
        If not, compiles the type. 
    #>
    param(
    [Parameter(Mandatory=$true, 
        HelpMessage="The C Library Containing the Function, i.e. User32")]
    [String]
    $Library,
    
    [Parameter(Mandatory=$true,
        HelpMessage="The Signature of the Method, i.e.: int GetSystemMetrics(uint Metric)")]
    [String]
    $Signature,
    
    [Switch]
    $OutputText
    )
    
    process {
        if ($Library -notlike "*.dll*") {
            $Library+=".dll"
        }
        if ($signature -notlike "*;") {
            $Signature+=";"
        }
        if ($signature -notlike "public static extern*") {
            $signature = "public static extern $signature"
        }
        
        $name = $($signature -replace "^.*?\s(\w+)\(.*$",'$1')
        
        $MemberDefinition = "[DllImport(`"$Library`")]`n$Signature"
        
        if (-not $OutputText) {
            $type = Add-Type -PassThru -Name "PInvoke$(Get-Random)" -MemberDefinition $MemberDefinition
            iex "New-Item Function:Global:$name -Value { [$($type.FullName)]::$name.Invoke( `$args ) }"
        } else {
            $MemberDefinition
        }
    }
}
