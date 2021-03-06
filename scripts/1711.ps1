#requires -version 2.0
#History:
# 1.0  - First public release (March 19, 2010)

function Get-Type {
    <#
    .Synopsis
        Gets the types that are currenty loaded in .NET, 
        or gets information about a specific type
    .Description
        Gets all of the loaded types, or gets the possible values for an 
        enumerated type or value.
    .Example
        # Gets all loaded types
        Get-Type
    .Example
        # Gets types from System.Management.Automation
        Get-Type -Assembly ([PSObject].Assembly)
    .Example
        # Gets all of the possible values for the ApartmentState property
        [Threading.Thread]::CurrentThread.ApartmentState | Get-Type
    .Example
        # Gets all of the possible values for an apartmentstate
        [Threading.ApartmentState] | Get-Type
    #>
    [CmdletBinding(DefaultParameterSetName="Assembly")]   
    param(
    # The assembly to collect types from
    [Parameter(ParameterSetName="Assembly", ValueFromPipeline=$true, Position=0)]
    [Reflection.Assembly[]]$Assembly
,
    # The enumerated value to get all of the possibilties of
    [Parameter(ParameterSetName="Enum", ValueFromPipeline=$true, Position=0)]
    [Enum]$Enum
,
    # Returns possible values if the Type was an enumerated value
    # Otherwise, returns the static members of the type
    [Parameter(ParameterSetName="Type", ValueFromPipeline=$true, Position=0)]
    [Type[]]$Type
    )

    process {
        switch ($psCmdlet.ParameterSetName) {
            Assembly {
                if (! $psBoundParameters.Count -and ! $args.Count) {
                    $Assembly = [AppDomain]::CurrentDomain.GetAssemblies()
                }
                foreach ($asm in $assembly) {
                    if ($asm) { $asm.GetTypes() }  
                }
            }
            Type {
                foreach ($t in $type) {
                    if ($t.IsEnum) {
                        [Enum]::GetValues($t)
                    } else {
                        $t  | Get-Member -static
                    }                
                }
            }
            Enum {
                [Enum]::GetValues($enum.GetType())        
            }
       }
    }
}

function Add-Assembly {
#.Synopsis
#  Load assemblies 
#.Description
#  Load assemblies from a folder
#.Parameter Path
#  Specifies a path to one or more locations. Wildcards are permitted. The default location is the current directory (.).
#.Parameter Passthru
#  Returns System.Runtime objects that represent the types that were added. By default, this cmdlet does not generate any output.
#  Aliased to -Types
#.Parameter Recurse
#  Gets the items in the specified locations and in all child items of the locations.
# 
#  Recurse works only when the path points to a container that has child items, such as C:\Windows or C:\Windows\*, and not when it points to items that do not have child items, such as C:\Windows\*.dll
param(
   [Parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true, Position=0)]
   [Alias("PSPath")]
   [string[]]$Path = "."
,
   [Alias("Types")]
   [Switch]$Passthru
,
   [Switch]$Recurse
)
process {
   foreach($file in Get-ChildItem $Path -Filter *.dll -Recurse:$Recurse) {
      Add-Type -Path $file.FullName -Passthru:$Passthru | Where { $_.IsPublic }
   }
}
}


function Get-Assembly {
<#
.Synopsis 
   Get a list of assemblies available in the runspace
.Description
   Returns AssemblyInfo for all the assemblies available in the current AppDomain, optionally filtered by partial name match
.Parameter Name
   A regex to filter the returned assemblies. This is matched against the .FullName of the assembly.
#>
param(
   [Parameter(ValueFromPipeline=$true, Position=0)]
   [string]$Name = ''
)
process {
   [appdomain]::CurrentDomain.GetAssemblies() |? {$_.FullName -match $Name}
}
}

Set-Alias gasm Get-Assembly

function Get-Constructor {
<#
.Synopsis 
   Get a list of constructors for a type
.Description
   Returns AssemblyInfo for all the assemblies available in the current AppDomain, optionally filtered by partial name match
.Parameter Name
   A regex to filter the returned assemblies. This is matched against the .FullName of the assembly.
#>
param( 
   [Parameter(ValueFromPipeline=$true, Position=0)]
   [Type]$type 
)
process {
   $type.GetConstructors() | 
      Format-Table @{
         l="$($type.Name) Constructors"
         e={ ($_.GetParameters() | % { $_.ToString() }) -Join ", " }
      }
}
}

Set-Alias gctor Get-Constructor

