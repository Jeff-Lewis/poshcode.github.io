#-------------------------------------------------------------------------    
# Script that will: 
# 1. Create a workspace. Workspacce Name: _Root
# 2. Get the latest code from repository
#-------------------------------------------------------------------------   
Param(
    [switch]
    $CSRWEB,
    [switch]
    $CSRWS,
    [switch]
    $CSRServices,
    [string]
    $LogPath
)
Begin 
{
    
    If ($LogPath) 
    {
        IF (-NOT (Test-Path $LogPath)) 
        {
            throw "Log Path:$($LogPath) not found!"
        }
    }

    $MSBUILD="c:\WINDOWS\Microsoft.NET\Framework\v3.5\MsBuild"
    $WEBPROJECTOUTPUTDIR="$OUTDIR\CSRWeb"
    $SCRIPT:Outdir = "C:\Application\CSR";

    #-------------------------------------------------------------------------    
    Function SetTFS
    {
        $SCRIPT:tfsServer = "172.29.4.179"
        $script:userName = [system.environment]::UserName; 
        $script:computerName = [system.environment]::machinename
        $script:workspaceName = $computerName + "_" + $userName +"_WS"   #Use 'WS' as an acronym for "WorkSpace"
        $script:CSRDIR = "C:\Brassring2\Application\"; 
        $script:WEBPROJECTOUTPUTDIR="$Outdir\CSRWeb"
        $script:WEBPROJECTOUTPUTDIR1="$Outdir\CSRWS"
        $script:WEBPROJECTOUTPUTDIR2="$Outdir\CSRServices"
        $script:REFPATH="referenceToAllAssembiesUsedInTheProjectSeperatedbySemiColon"
        $script:MSBUILD="c:\WINDOWS\Microsoft.NET\Framework\v3.5\MsBuild"
        $script:failed = $false

        # Set up the TF Alias


        # Find where VS is installed. 
        $key = Get-ItemProperty HKLM:\SOFTWARE\Microsoft\VisualStudio\9.0
        $dir = [string] (Get-ItemProperty $key.InstallDir)
        $script:tf = "$dir\tf.exe"
    } # End SetTFS

    #-------------------------------------------------------------------------    
    Function CreateWorkspace
    {
        Begin {
            Function DeleteWorkspace
            {
                # Delete the workspace if it exists. 
                echo "Deleting workspace (if exists): $workspaceName" | Tee-Object -Variable Log
                
                &$TF workspace /delete  $workspaceName  /noprompt | out-null

                echo "Done deleting workspace." | Tee-Object -Variable Log
            } #END DeleteWorkspace
        }
        Process {
            DeleteWorkspace
        
            # Create the folder
            if (! (Test-Path $CSRDIR)) {
                echo "Creating folder: $CSRDIR" | Tee-Object -Variable Log
                new-item -itemtype directory -path $CSRDIR -force | out-null
                echo "Completed Creating folder: $CSRDIR" | Tee-Object -Variable Log
            }
            # Move to folder
            cd $CSRDIR

            # Create the workspace 
            echo "Creating workspace: $workspaceName" | Tee-Object -Variable Log

            &$TF workspace /new /computer:$computerName /server:$TFsServer /noprompt $workspaceName

            echo "Done Creating workspace: $workspaceName" | Tee-Object -Variable Log

            # Get the latest
            echo "Getting the latest code from: $TFsServer. This could take awhile..." | Tee-Object -Variable Log
            &$TF get $/CSR/CSR /recursive

            echo "Done getting latest."  | Tee-Object -Variable Log

            echo "Tree initialization is complete." | Tee-Object -Variable Log
        } 
    } #END CreateWorkspace
   
    #-------------------------------------------------------------------------
    # Get Next Label
    #
    # Labels are BL{major}.{minor}
    # major = 1 - ???
    # minor = 001 - 999
    #-------------------------------------------------------------------------
    Function GetNextLabel()
    {
        $major = 1
        $minor = 1
       
        $list = (&$TF labels /format:brief |? { $_ -notmatch "-.+" -and $_ -notmatch "Label.+Owner.+Date"})
        
        if ($list -ne $null) {
           
            # Split label into major minor
            $major,[int]$minor= (($list | Select-Object -last 1).split()).split(".")
        
            # Increment minor label
            $minor++
            
            # Remove BL from string, and cast to int
            [int]$major = $major.substring(2)
            
            # If minor gt 999 increment major and reset minor
            if ($minor -gt 999) {
                $major++
                $minor = 1
            }
        }
        
        # return label
        $label = "BL{0}.{1:000}" -f $major, $minor
        
        return $label
    }
    
    #-------------------------------------------------------------------------
    Function MSBuild($outputdir, $webproject, $project, $ref)
    {
        # I think this can be cleaned up with where-object, but it's too important to play with
        $failed = $false
        &$MSBUILD /p:Configuration=Release  /p:OutDir=$Outputdir /p:WebProjectOutputDir=$webproject $project |% {
                if ($_ -match "Build FAILED") { $failed = $true } ; $_ 
            }
        if ($failed) { throw (new-object NullReferenceException) }    
        
        $failed = $false
        &$MSBUILD /p:Configuration=Release /t:ResolveReferences /p:OutDir=$Outputdir\bin\ /p:ReferencePath=$ref $project  |% {
                if ($_ -match "Build FAILED") { $failed = $true } ; $_ 
            }
        if ($failed) { throw (new-object NullReferenceException) }    
    }

    #-------------------------------------------------------------------------
    # Create the Label
    #-------------------------------------------------------------------------
    Function ApplyLabel()
    {
        Write-Host "Create the Label" | Tee-Object -Variable Log

        $label = GetNextLabel
            
        &$TF label  $label  $/CSR/CSR /recursive

        &$TF get /version:L$($label)

        Write-Host "Applied label $label" | Tee-Object -Variable Log

        return $Label    
    } # END ApplyLabel
} # End Begin
Process 
{
    trap [Exception] 
    {
        write-host "Build Failed" | Tee-Object -Variable Log
        exit 1;
    }
    . SetTFS
    . CreateWorkspace
    . ApplyLabel
    
    IF (!$CSRWS -AND !$CSRWEB -AND !$CSRServices)
    {
        Write-Debug "No Options Found Setting ALL"
        $CSRWS = $TRUE
        $CSRWEB = $TRUE
        $CSRServices = $TRUE
    }
    
    Switch ("") 
    {
        {$CSRWEB}
            {
                Write-Host "Building CSRWEB" | Tee-Object -Variable Log
                
                MsBuild "$Outdir\CSRWeb\" $WEBPROJECTOUTPUTDIR " $CSRDIR\CSR\CSR\CSRWeb\CSRWeb\CSRWeb.csproj" $REFPATH
                
                # ©-item C:\TFSMAIN\CSR\bin\Microsoft.ApplicationBlocks.Data.dll $CSRDIR\CSRWeb\bin\ -credential 
                # ©-item C:\TFSMAIN\CSR\bin\Microsoft.Practices.EnterpriseLibrary.Caching.dll $CSRDIR\CSRWeb\bin\ -credential 
                # ©-item C:\TFSMAIN\CSR\bin\Microsoft.Practices.ObjectBuilder.dll $CSRDIR\CSRWeb\bin\ -credential 

                rm  $Outdir\CSRWeb\*.config -recurse
                rm  $Outdir\CSRWeb\*.pdb -recurse
                rm  $Outdir\CSRWeb\*.dll -recurse
                rm  $Outdir\CSRWeb\*.xml -recurse
                rm  $Outdir\CSRWeb\bin\*.pdb -recurse
                rm  $Outdir\CSRWeb\bin\*.config -recurse
                rm  $Outdir\CSRWeb\bin\*.xml -recurse
                
                Write-Host : "Build CSRWEB Successful"  | Tee-Object -Variable Log
            }
        {$CSRWS}
            {
                Write-Host "Building CSRWS"  | Tee-Object -Variable Log
        
                MsBuild "$Outdir\CSRWS\" $WEBPROJECTOUTPUTDIR1 "$CSRDIR\CSR\CSR\CSRWS\CSRWS\CSRWS.csproj" $REFPATH
                
                # ©-item C:\TFSMAIN\CSR\bin\Microsoft.ApplicationBlocks.Data.dll $CSRDIR\CSRWeb\bin\ -credential 
                # ©-item C:\TFSMAIN\CSR\bin\Microsoft.Practices.EnterpriseLibrary.Caching.dll $CSRDIR\CSRWeb\bin\ -credential 
                # ©-item C:\TFSMAIN\CSR\bin\Microsoft.Practices.ObjectBuilder.dll $CSRDIR\CSRWeb\bin\ -credential 

                rm  $Outdir\CSRWS\*.config -recurse
                rm  $Outdir\CSRWS\*.pdb -recurse
                rm  $Outdir\CSRWS\*.dll -recurse
                rm  $Outdir\CSRWS\*.xml -recurse
                rm  $Outdir\CSRWS\bin\*.pdb -recurse
                rm  $Outdir\CSRWS\bin\*.config -recurse
                rm  $Outdir\CSRWS\bin\*.xml -recurse
                
                Write-Host : "Build CSRWS Successful"  | Tee-Object -Variable Log
            }
        {$CSRServices}
            {
            Write-Host "Building CSR Services" | Tee-Object -Variable Log
        
            MsBuild "$Outdir\CSRSERVICES\" $WEBPROJECTOUTPUTDIR2 "CSRDIR\CSR\CSR\CSRSERVICES\CSRSERVICES\CSRSERVICES.csproj" $REFPATH
            
            # ©-item C:\TFSMAIN\CSR\bin\Microsoft.ApplicationBlocks.Data.dll $CSRDIR\CSRWeb\bin\ -credential 
            # ©-item C:\TFSMAIN\CSR\bin\Microsoft.Practices.EnterpriseLibrary.Caching.dll $CSRDIR\CSRWeb\bin\ -credential 
            # ©-item C:\TFSMAIN\CSR\bin\Microsoft.Practices.ObjectBuilder.dll $CSRDIR\CSRWeb\bin\ -credential 

            rm  $Outdir\CSRSERVICES\*.config -recurse
            rm  $Outdir\CSRSERVICES\*.pdb -recurse
            rm  $Outdir\CSRSERVICES\*.dll -recurse
            rm  $Outdir\CSRSERVICES\*.xml -recurse
            rm  $Outdir\CSRSERVICES\bin\*.pdb -recurse
            rm  $Outdir\CSRSERVICES\bin\*.config -recurse
            rm  $Outdir\CSRSERVICES\bin\*.xml -recurse
            
            Write-Host : "Build CSR Services Successful"  | Tee-Object -Variable Log
            }
    }
} #End Process
End 
{
    IF ($LogPath) 
    {
        Out-file -InputObject $Log -Encoding ascii 
    }
} #END End
