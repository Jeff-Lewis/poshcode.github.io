
function Export-DefaultParameter {
#.Synopsis
#  Exports the current default parameter values
[CmdletBinding()]
param(
   # The path to export default parameter values to (defaults to "DefaultParameterValues.clixml" in your profile directory)
   [String]$Path = $(Join-Path (Split-Path $Profile.CurrentUserAllHosts -Parent) DefaultParameterValues.clixml)
)
   Export-CliXml -InputObject $Global:PSDefaultParameterValues -Path $Path
}

function Import-DefaultParameter {
#.Synopsis
#  Imports new default parameter values
[CmdletBinding()]
param(
   # The path to import default parameter values from (defaults to "DefaultParameterValues.clixml" in your profile directory)
   [String]$Path = $(Join-Path (Split-Path $Profile.CurrentUserAllHosts -Parent) DefaultParameterValues.clixml),
   # If set, overwrite current values (otherwise, keep current values)
   [Switch]$Force
)

   $TempParameterValues = $Global:PSDefaultParameterValues
   if(Test-Path $Path) {
      [System.Management.Automation.DefaultParameterDictionary]$NewValues = 
            Import-CliXml  -Path ${ProfileDir}\DefaultParameterValues.clixml
      
      foreach($key in $NewValues.Keys) {
         if($Global:PSDefaultParameterValues.ContainsKey($key)) {
            if($Force) {
               $Global:PSDefaultParameterValues.$Key = $NewValues.$key
            } else {
               Write-Warning ("Key already defined, use -Force to overwrite:`n{0} = {1}" -f $Key, $NewValues.$key)
            }
         } else {
            $Global:PSDefaultParameterValues.$Key = $NewValues.$key
         }
      }
   } else {
      Write-Warning "Default Parameter file not found: '$Path'"
   }
}

function Set-DefaultParameter {
#.Synopsis
#  Sets a default parameter value for a command
#.Description
#  Safely sets the default parameter value for a command, making sure that you've correctly typed the command and parameter combination
[CmdletBinding(DefaultParameterSetName="Colonated")]
param(
   # The command that you want to change the default value of a parameter for
   [parameter(Position=0,Mandatory=$true)]
   $command,
   # The name of the parameter that you want to change the default value for
   [parameter(Position=1,Mandatory=$true,ParameterSetName="SeparateInputs")]
   $parameter,
   # The new default parameter value
   [parameter(Position=2,Mandatory=$true)]
   $value
)

   if($PSCmdlet.ParameterSetName -eq "Colonated") {
      $parameter = $command -split ":"
   }
   if($parameter.StartsWith("-")) {
      $parameter = $parameter.TrimStart("-")
   }
 
   ## Resolve the parameter to be sure
   $cmd = Get-Command $command
   $parameters = $cmd.ParameterSets | Select -expand Parameters
   $param = @($parameters | Where-Object { $_.Name -match $parameter -or $_.Aliases -match $parameter} | Select -Expand Name -Unique)
   if($param.Count -eq 1) {
      Write-Verbose "Parameter $parameter => $($param[0])"
      $Global:PSDefaultParameterValues["${Command}:$($param[0])"] = $Value
   }
}

function Disable-DefaultParameter {
#.Synopsis
#  Turns OFF default parameters
#.Description
#  By setting $PSDefaultParameterValues["Disable"] to $true, we make sure that NONE of our default parameter values will be used
[CmdletBinding()]
param()
   $Global:PSDefaultParameterValues["Disable"]=$true
}

function Enable-DefaultParameter {
#.Synopsis
#  Turns ON default parameters
#.Description
#  By setting $PSDefaultParameterValues["Disable"] to $false, we make sure that all of our default parameter values will be used
[CmdletBinding()]
param()
   $Global:PSDefaultParameterValues["Disable"]=$false
}
Set-Alias Add-DefaultParameter Set-DefaultParameter -ErrorAction SilentlyContinue
Import-DefaultParameter
