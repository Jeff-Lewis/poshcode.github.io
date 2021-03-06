function New-Module {
   #.Synopsis
   #  Generate a new module from some script files
   #.Description
   #  New-Module serves two ways of creating modules, but in either case, it can generate the psd1 and psm1 necessary for a module based on script files.
   #
   #  In one use case, it's just a simplified wrapper for New-ModuleManifest which answers some of the parameters based on the files already in the module folder.
   #
   #  In the second use case, it allows you to collect one or more scripts and put them into a new module folder.
   [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact="Medium", DefaultParameterSetName="NewModuleManifest")]
   param(
      # If set, overwrites existing modules without prompting
      [Switch]$Force,

      # The name of the module to create
      [Parameter(Position=0, Mandatory=$true)]
      $ModuleName,

      # The script files to put in the module. Should be .ps1 files (but could be .psm1 too)
      [Parameter(Position=1,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName="OverwriteModule",Mandatory=$true)]
      [ValidateScript({
         foreach($path in $_){
            if(!(Test-Path $path)) {
               throw "No files matching '$path' found."
            }
         }
         $true
      })]
      [Alias("PSPath")]
      $File,

      # The name of the author to use for the psd1 and copyright statement
      [String]$Author = $Env:UserName,

      # A short description of the contents of the module.
      [Parameter(Position=1)]
      [string]${Description} = "A collection of script files by $Author",

      # (This is a passthru for New-ModuleManifest)
      [AllowEmptyString()]
      [String]$CompanyName = $null,

      # If set, enforces the allowed verb names on function exports
      [Switch]$StrictVerbs,

      # Specifies the minimum version of the Common Language Runtime (CLR) of the Microsoft .NET Framework that the module requires (Should be 2.0 or 4.0). Defaults to the (rounded) currently available ClrVersion.
      # (This is a passthru for New-ModuleManifest)
      [version]
      ${ClrVersion} = $($PSVersionTable.CLRVersion.ToString(2)),

      # Specifies the minimum version of Windows PowerShell that will work with this module. Defaults to 1 less than your current version.
      # (This is a passthru for New-ModuleManifest)
      [version]
      ${PowerShellVersion} = $("{0:F1}" -f (([Double]$PSVersionTable.PSVersion.ToString(2)) - 1.0)),
      
      # Specifies modules that this module requires. (This is a passthru for New-ModuleManifest)
      [System.Object[]]
      ${RequiredModules} = $null,
      
      # Specifies the assembly (.dll) files that the module requires. (This is a passthru for New-ModuleManifest)
      [AllowEmptyCollection()]
      [string[]]
      ${RequiredAssemblies} = $null
   )

   begin {
      # Make sure ModuleName isn't really a path ;)
      if(Test-Path $ModuleName) {
         $ModulePath = Resolve-Path $ModuleName
      } else {
         if(!$ModuleName.Contains([io.path]::DirectorySeparatorChar) -and !$ModuleName.Contains([io.path]::AltDirectorySeparatorChar)) {
            $ModulePath = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "WindowsPowerShell\Modules\$ModuleName"
         } else {
            $ModulePath = $ModuleName
         }
      }
      $ModuleName = Split-Path $ModuleName -Leaf

      Write-Host "Creating a new module $ModuleName in $ModulePath"

      $ScriptFiles = @()
   }

   process {
      $ScriptFiles += $File
   }

   end {
      # If there are errors in here, we need to stop before we really mess something up.
      $ErrorActionPreference = "Stop"

      # We support either generating a module from an existing module folder, 
      # or generating a module from loose files (but not both)
      if($ScriptFiles) {
         # We have script files, so let's make sure the folder is empty and then put our files in it
         if(Test-Path $ModulePath) {
            if($Force -Or $PSCmdlet.ShouldContinue("The specified Module already exists: '$ModulePath'. Do you want to delete it and start over?", "Deleting '$ModulePath'")) {
               Remove-Item $ModulePath -recurse
            } else {
               throw "The specified ModuleName '$_' already exists in '$Path'. Please choose a new name, or specify -Force to overwrite that folder."
            }
         }

         $null = New-Item -Type Directory $ModulePath

         # Copy the scripts into the ModulePath
         foreach($file in $ScriptFiles) {
            $Destination = Join-Path $ModulePath ( Resolve-Path $file -Relative )
            if(!(Test-Path (Split-Path $Destination))) {
               $null = New-Item -Type Directory (Split-Path $Destination)
            }
            Copy-Item $file $Destination
         }
      }

      # We need to run the rest of this (especially the New-ModuleManifest stuff) from the ModulePath
      Push-Location $ModulePath

      # Create the RootModule if it doesn't exist yet
      if($Force -Or !(Test-Path "${ModuleName}.psm1") -or $PSCmdlet.ShouldContinue("The specified '${ModuleName}.psm1' already exists in '$ModulePath'. Do you want to overwrite it?", "Creating new '${ModuleName}.psm1'")) {
         Set-Content "${ModuleName}.psm1" @'
Push-Location $PSScriptRoot
Import-LocalizedData -BindingVariable ModuleManifest
$ModuleManifest.FileList -like "*.ps1" | % {
    $Script = Resolve-Path $_ -Relative
    Write-Host "Loading $Script"
    . $Script
}
Pop-Location
'@
      }

      if($Force -Or !(Test-Path "${ModuleName}.psd1") -or $PSCmdlet.ShouldContinue("The specified '${ModuleName}.psd1' already exists in '$ModulePath'. Do you want to overwrite it?", "Creating new '${ModuleName}.psd1'")) {

         # We'll list all the files in the module
         $FileList = Get-ChildItem -Recurse | Where { !$_.PSIsContainer } | Resolve-Path -Relative

         $verbs = if($Strict){ Get-Verb | % { $_.Verb +"-*" } } else { "*-*" }

         $null = $PSBoundParameters.Remove("File")
         $null = $PSBoundParameters.Remove("Force")
         $null = $PSBoundParameters.Remove("ModuleName")

         $ModuleInfo = @{
            Path = "${ModuleName}.psd1"
            RootModule = "${ModuleName}.psm1"
            FileList = $FileList
            TypesToProcess = $FileList -match ".*Types?\.ps1xml"
            FormatsToProcess = $FileList -match ".*Formats?\.ps1xml"
            NestedModules = $FileList -like "*.psm1" -notlike "${ModuleName}.psm1"
            FunctionsToExport = $Verbs
            AliasesToExport = "*"
            CmdletsToExport = $null
            VariablesToExport = "${ModuleName}*"
         } + $PSBoundParameters 

         New-ModuleManifest @ModuleInfo
      }

      Pop-Location
   }
}
