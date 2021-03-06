#Requires -version 2.0

#.Synopsis
#  Enumerates the parameters of one or more commands
#.Notes
#  With many thanks to Hal Rottenberg, Oisin Grehan and Shay Levy
#  Version 0.80 - April 2008 - By Hal Rottenberg http://poshcode.org/186
#  Version 0.81 - May 2008 - By Hal Rottenberg http://poshcode.org/255
#  Version 0.90 - June 2008 - By Hal Rottenberg http://poshcode.org/445
#  Version 0.91 - June 2008 - By Oisin Grehan http://poshcode.org/446
#  Version 0.92 - April 2008 - By Hal Rottenberg http://poshcode.org/549
#               - Added resolving aliases and avoided empty output
#  Version 0.93 - Sept 24, 2009 - By Hal Rottenberg http://poshcode.org/1344
#  Version 1.0  - Jan 19, 2010 - By Joel Bennett http://poshcode.org/1592
#               - Merged Oisin and Hal's code with my own implementation
#               - Added calculation of dynamic paramters
#  Version 2.0  - July 22, 2010 - By Joel Bennett http://poshcode.org/get/2005
#               - Now uses FormatData so the output is objects
#               - Added calculation of shortest names to the aliases (idea from Shay Levy http://poshcode.org/1982, but with a correct implementation)
#  Version 2.1  - July 22, 2010 - By Joel Bennett http://poshcode.org/2007
#               - Fixed Help for SCRIPT file (script help must be separated from #Requires by an emtpy line)
#               - Fleshed out and added dates to this version history after Bergle's criticism ;)
#  Version 2.2  - July 29, 2010 - By Joel Bennett (This Version)
#               - Fixed a major bug which caused Get-Parameters to delete all the parameters from the CommandInfo
#  Version 2.3  - July 29, 2010 - By Joel Bennett (This Version)
#               - Added a ToString ScriptMethod which allows queries like:
#                 $parameters = Get-Parameter Get-Process; $parameters -match "Name"
#
#.Description
#  Lists all the parameters of a command, by ParameterSet, including their aliases, type, etc.
#
#  By default, formats the output to tables grouped by command and parameter set
#.Example
#  Get-Command Select-Xml | Get-Parameter
#.Example
#  Get-Parameter Select-Xml
#.Parameter Name
#  The name of the command to get parameters for
#.Parameter ModuleName
#  The name of the module which contains the command (this is for scoping)
#.Parameter Force
#  Forces including the CommonParameters in the output
[CmdletBinding()]
##This is just script-file nesting stuff, so that you can call the SCRIPT, and after it defines the global function, it will call it.
param ( 
   [Parameter(Position=1,ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
   [string[]]$Name
,
   [Parameter(Position=2,ValueFromPipelineByPropertyName=$true,Mandatory=$false)]
   $ModuleName
,
   [switch]$Force
)

Function global:Get-Parameter {
#.Synopsis 
#  Enumerates the parameters of one or more commands
#.Description
#  Lists all the parameters of a command, by ParameterSet, including their aliases, type, etc.
#
#  By default, formats the output to tables grouped by command and parameter set
#.Example
#  Get-Command Select-Xml | Get-Parameter
#.Example
#  Get-Parameter Select-Xml
#.Parameter Name
#  The name of the command to get parameters for
#.Parameter ModuleName
#  The name of the module which contains the command (this is for scoping)
#.Parameter Force
#  Forces including the CommonParameters in the output
[CmdletBinding()]
param ( 
   [Parameter(Position=1,ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
   [string[]]$Name
,
   [Parameter(Position=2,ValueFromPipelineByPropertyName=$true,Mandatory=$false)]
   $ModuleName
,
   [switch]$Force
)
begin {
   $PropertySet = @( "Name",
                     @{n="Position";e={if($_.Position -lt 0){"Named"}else{$_.Position}}},
                     "Aliases", 
                     @{n="Short";e={$_.Name}},
                     @{n="Type";e={$_.ParameterType.Name}}, 
                     @{n="ParameterSet";e={$paramset}},
                     @{n="Command";e={$command}},
                     @{n="Mandatory";e={$_.IsMandatory}},
                     @{n="Provider";e={$_.DynamicProvider}},
                     @{n="ValueFromPipeline";e={$_.ValueFromPipeline}},
                     @{n="ValueFromPipelineByPropertyName";e={$_.ValueFromPipelineByPropertyName}}
                  )
   function Join-Object {
   Param(
      [Parameter(Position=0)]
      $First
   ,
      [Parameter(ValueFromPipeline=$true,Position=1)]
      $Second
   )
      begin {
         [string[]] $p1 = $First | gm -type Properties | select -expand Name
      }
      process {
         $Output = $First | Select $p1
         foreach($p in $Second | gm -type Properties | Where { $p1 -notcontains $_.Name } | select -expand Name) {
            Add-Member -in $Output -type NoteProperty -name $p -value $Second."$p"
         }
         $Output
      }
   }
}
process{
   foreach($cmd in $Name) {
      if($ModuleName)   { $cmd = "$ModuleName\$cmd" }
      $commands = @(Get-Command $cmd)

      foreach($command in $commands) {
         # resolve aliases (an alias can point to another alias)
         while ($command.CommandType -eq "Alias") {
            $command = @(Get-Command ($command.definition))[0]
         }
         if (-not $command) { continue }

         $Parameters = @{}

         foreach($provider in Get-PSProvider) {
            $drive = "{0}\{1}::\" -f $provider.ModuleName, $provider.Name
            Write-Verbose ("Get-Command $command -Args $drive | Select -Expand Parameters")
            
            [Array]$MoreParameters = (Get-Command $command -Args $drive).Parameters.Values
            [Array]$Dynamic = $MoreParameters | Where { $_.IsDynamic }
             
            foreach($p in $MoreParameters | Where { $Dynamic -notcontains $_ } ){ 
               $Parameters.($p.Name) = $p
            }
            
            # Write-Verbose "Drive: $Drive | Parameters: $($Parameters.Count)"
            if($dynamic) {
               foreach($d in $dynamic) {
                  if(Get-Member -input $Parameters.($d.Name) -Name DynamicProvider) {
                     Write-Debug ("ADD:" + $d.Name + " " + $provider.Name)
                     $Parameters.($d.Name).DynamicProvider += $provider.Name
                  } else {
                     Write-Debug ("CREATE:" + $d.Name + " " + $provider.Name)
                     $Parameters.($d.Name) = $Parameters.($d.Name) | Add-Member NoteProperty DynamicProvider @($provider.Name) -Passthru
                  }
               }
            }
         }
         
         ## Calculate the shortest distinct parameter name -- do this BEFORE removing the common parameters or else.
         foreach($p in $($Parameters.Keys))
         {
            $shortest="^"
            foreach($char in [char[]]$p)
            {             
               $shortest += $char
               $Matches = ($Parameters.Keys -match $Shortest).Count
               Write-Debug "$($shortest.SubString(1)) $Matches"
               if($Matches -eq 1)
               {
                  $Parameters.$p = $Parameters.$p | Add-Member NoteProperty Aliases ($Parameters.$p.Aliases + @($shortest.SubString(1).ToLower($PSUICulture))) -Force -Passthru
                  break
               }
            }
         }
   
         Write-Verbose "Parameters: $($Parameters.Count)`n $($Parameters | ft | out-string)"
        
         foreach ($paramset in @($command.ParameterSets | Select -Expand "Name")){
            foreach($parameter in $Parameters.Keys | Sort) {
               Write-Verbose "Parameter: $Parameter"
               if(!$Force -and ($Parameters.$Parameter.aliases -match "vb|db|ea|wa|ev|wv|ov|ob|wi|cf")) { continue }
               if($Parameters.$Parameter.ParameterSets.ContainsKey($paramset) -or $Parameters.$Parameter.ParameterSets.ContainsKey("__AllParameterSets")) {                  
                  if($Parameters.$Parameter.ParameterSets.ContainsKey($paramset)) { 
                     $output = Join-Object $Parameters.$Parameter $Parameters.$Parameter.ParameterSets.$paramSet 
                  } else {
                     $output = Join-Object $Parameters.$Parameter $Parameters.$Parameter.ParameterSets.__AllParameterSets
                  }
                  
                  
                  
                  Write-Output $Output | Select-Object $PropertySet | ForEach {
                     $null = $_.PSTypeNames.Insert(0,"System.Management.Automation.ParameterMetadata")
                     $null = $_.PSTypeNames.Insert(0,"System.Management.Automation.ParameterMetadataEx")
                     Write-Verbose "$(($_.PSTypeNames.GetEnumerator()) -join ", ")"
                     $_
                  } | Add-Member ScriptMethod ToString { $this.Name } -Force -Passthru
               }
            }
         }
      }
   }
}
}


# Since you can't update format data without a file that has a ps1xml ending, let's make one up...
$tempFile = "$([IO.Path]::GetTempFileName()).ps1xml"
Set-Content $tempFile @'
<?xml version="1.0" encoding="utf-8" ?>
<Configuration>
    <Controls>
        <Control>
            <Name>ParameterGroupingFormat</Name>
              <CustomControl>
                  <CustomEntries>
                      <CustomEntry>
                          <CustomItem>
                              <Frame>
                                  <LeftIndent>4</LeftIndent>
                                  <CustomItem>
                                      <Text>Command: </Text>
                                      <ExpressionBinding>
                                          <ScriptBlock>"{0}/{1}" -f $(if($_.command.ModuleName){$_.command.ModuleName}else{$_.Command.CommandType.ToString()+":"}),$_.command.Name</ScriptBlock>
                                      </ExpressionBinding>
                                      <NewLine/>
                                      <Text>Set:     </Text>
                                      <ExpressionBinding>
                                          <ScriptBlock>if($_.ParameterSet -eq "__AllParameterSets"){"Default"}else{$_.ParameterSet}</ScriptBlock>
                                      </ExpressionBinding>
                                      <NewLine/>
                                  </CustomItem> 
                              </Frame>
                          </CustomItem>
                      </CustomEntry>
                  </CustomEntries>
            </CustomControl>
        </Control>
    </Controls>
    <ViewDefinitions>
        <View>
            <Name>ParameterMetadataEx</Name>
            <ViewSelectedBy>
                <TypeName>System.Management.Automation.ParameterMetadataEx</TypeName>
            </ViewSelectedBy>
            <GroupBy>
                <PropertyName>ParameterSet</PropertyName>
                <CustomControlName>ParameterGroupingFormat</CustomControlName>  
            </GroupBy>
            <TableControl>
                <TableHeaders>
                    <TableColumnHeader>
                        <Label>Name</Label>
                        <Width>22</Width>
                    </TableColumnHeader>
                    <TableColumnHeader>
                        <Label>Aliases</Label>
                        <Width>12</Width>
                    </TableColumnHeader>
                    <TableColumnHeader>
                        <Label>Position</Label>
                        <Width>8</Width>
                    </TableColumnHeader>
                    <TableColumnHeader>
                        <Label>Mandatory</Label>
                        <Width>9</Width>
                    </TableColumnHeader>
                    <TableColumnHeader>
                        <Label>Pipeline</Label>
                        <Width>8</Width>
                    </TableColumnHeader>
                    <TableColumnHeader>
                        <Label>ByName</Label>
                        <Width>6</Width>
                    </TableColumnHeader>
                    <TableColumnHeader>
                        <Label>Provider</Label>
                        <Width>15</Width>
                    </TableColumnHeader>
                    <TableColumnHeader>
                        <Label>Type</Label>
                    </TableColumnHeader>
                </TableHeaders>
                <TableRowEntries>
                    <TableRowEntry>
                        <TableColumnItems>
                            <TableColumnItem>
                                <PropertyName>Name</PropertyName>
                            </TableColumnItem>
                            <TableColumnItem>
                                <PropertyName>Aliases</PropertyName>
                            </TableColumnItem>
                            <TableColumnItem>
                                <!--PropertyName>Position</PropertyName-->
                                <ScriptBlock>if($_.Position -lt 0){"Named"}else{$_.Position}</ScriptBlock>
                            </TableColumnItem>
                            <TableColumnItem>
                                <PropertyName>Mandatory</PropertyName>
                            </TableColumnItem>
                            <TableColumnItem>
                                <PropertyName>ValueFromPipeline</PropertyName>
                            </TableColumnItem>
                            <TableColumnItem>
                                <PropertyName>ValueFromPipelineByPropertyName</PropertyName>
                            </TableColumnItem>
                            <TableColumnItem>
                                <!--PropertyName>Provider</PropertyName-->
                                <ScriptBlock>if($_.Provider){$_.Provider}else{"All"}</ScriptBlock>
                            </TableColumnItem>
                            <TableColumnItem>
                                <PropertyName>Type</PropertyName>
                            </TableColumnItem>
                        </TableColumnItems>
                    </TableRowEntry>
                 </TableRowEntries>
            </TableControl>
        </View>
    </ViewDefinitions>
</Configuration>
'@

Update-FormatData -Append $tempFile


# This is nested stuff, so that you can call the SCRIPT, and after it defines the global function, we will call that.
Get-Parameter @PSBoundParameters

