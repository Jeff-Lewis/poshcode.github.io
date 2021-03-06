Function Find-TaskServiceUser { 
<# 
.SYNOPSIS 
   Finding Tasks, Services on remote/local computer.  
.DESCRIPTION 
   Finding Tasks, Services on remote/local computer with specific user. User 'Administrator' is default. 
   First do: 
   . .\Find-TaskServiceUser.ps1 
.PARAMETER User 
    Give user to search tasks/services. Default value is 'Administrator'. 
.PARAMETER Computer 
    Give computer to search tasks/services. Default value is 'localhost' ($env:COMPUTERNAME). 
.PARAMETER Task 
    if you want search tasks. 
.PARAMETER Service 
    if you want search services. 
.EXAMPLE 
    Find-TaskServiceUser -Computer computer_name -User User -Service -Task 
 
    Description 
    ----------- 
    To find services and tasks on 'computer_name' for user 'user'. 
.EXAMPLE 
   "comp1","comp2" | Find-TaskServiceUser -Service -Task 
 
    Description 
    ----------- 
    Stream two computers names to cmdlet to find services and tasks: 
.LINK 
   http://voytas.net 
.LINK 
   http://gallery.technet.microsoft.com/Find-tasks-and-53d1a77b 
.NOTES 
   Voytas 
    
   version 1.1, 5-5-2014: 
      - minor changes 
   version 1.0, may 2014: 
      - first build of cmdlet 
#> 
 
    [CmdletBinding()] 
    Param 
    ( 
        #Computer 
        [parameter( 
                   mandatory=$false, 
                   position=0, 
                   valuefrompipeline = $true, 
                   ValueFromPipelineByPropertyName=$true, 
                   HelpMessage='Computer NetBIOS, DNS name or IP.' 
                   )] 
        [Alias('MachineName','Server')] 
        [string[]] 
        $Computer=$env:COMPUTERNAME, 
 
        [parameter(Mandatory=$false, 
                   HelpMessage='User name to search services and/or tasks.' 
                  )] 
        [string]$User='Administrator', 
 
        # Searching in Services 
        [parameter(Mandatory=$false, 
                   HelpMessage='Switch to search services.' 
                  )] 
        [switch]$Service, 
 
        # Searching in Task scheduler 
        [parameter(Mandatory=$false, 
                   HelpMessage='Switch to search tasks.' 
                  )] 
        [switch]$Task 
    ) 
 
    Begin 
    { 
    $ErrorActionPreference_ = $ErrorActionPreference 
    $ErrorActionPreference = 'SilentlyContinue' 
 
    if (!$service -and !$task) { 
    Write-Output ' 
    Examples: 
      Find-TaskServiceUser -Computer computer_name -User User -Service -Task 
      "comp1","comp2" | Find-TaskServiceUser -Service -Task 
    ' 
    } 
     
    function Search-ServiceUser { 
      param ( 
      [parameter(mandatory=$true,position=0)] 
      [string[]]$computer, 
 
      [parameter(mandatory=$false,position=1)] 
      [string]$user 
      ) 
    $filter = "startname like '%$($user)%'" 
    $service_ = Get-WmiObject win32_service -filter "$filter" -ComputerName $computer 
    if ($service_) { 
      return $service_ 
    } # end function Search-ServiceUser 
} 
     
    function Search-TaskUser { 
    param( 
    [string]$server, 
 
    [string]$user 
    ) 
        $task_=Invoke-Expression "schtasks /query /s $server /fo csv /v" 
        $match_ = "$user" 
        $task_ | Where-Object {$_ -match $match_}  
    } 
    } # end BEGIN block 
    Process 
    { 
    if ($service) {     
        write-host "Searching services with user: $($user.trim().toupper()) on machine: $($computer.trim().toupper())" 
        $comp = $computer.Trim() 
        $services = Search-ServiceUser -computer $comp -user $user 
      if ($services) { 
          $services | select-object SystemName,Name,DisplayName,StartName,State | Format-Table -AutoSize 
      } else { 
       Write-Output 'No services' 
      } 
    } 
    if ($task){ 
        Write-Output "Searching tasks with user: $($user.trim().toupper()) on machine: $($computer.trim().toupper())" 
        $tasks = Search-TaskUser -server $computer -user $user 
      if ($tasks) { 
        Write-Output "Task with author or start as $user" 
        # problem ze split przez "," bo wystepuje takze w tekscie i zle dzieli ($b[7], $b[14]) 
        $tasks | %{ $b=$_.split(',');write-host $b[0], $b[1]} 
      } else { 
        Write-Output 'No tasks' 
      } 
    } 
    } # end PROCESS block 
    End 
    { 
    $ErrorActionPreference = $ErrorActionPreference_ 
    } # end END block 
} # end function Find-TaskServiceUser
