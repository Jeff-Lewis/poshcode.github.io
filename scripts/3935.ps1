# Uses NativeConsole, which is available under a bunch of Open Source licenses
# http://poshconsole.codeplex.com/SourceControl/changeset/view/f9bb2b127402#Huddled/Interop/NativeConsole.cs
add-type -Path ~\Projects\PoshConsole\Huddled\Interop\NativeConsole.cs

$NativeConsole = New-Object Huddled.Interop.NativeConsole

$ConsoleError = Register-ObjectEvent -InputObject $NativeConsole -EventName WriteError -Action { 
    Add-Content -Path $Pwd\Error.log -Value $EventArgs.Text
    Add-Content -Path $Pwd\Output.log -Value $EventArgs.Text
    Write-Error $EventArgs.Text
    # Fake output, so I get to see it immediately
    Write-Host $EventArgs.Text -ForegroundColor Red
}

$ConsoleOutput = Register-ObjectEvent -InputObject $NativeConsole -EventName WriteOutput -Action {
    Add-Content -Path $Pwd\Output.log -Value $EventArgs.Text
    Write-Output $EventArgs.Text 
    # Fake output, so I get to see it immediately
    Write-Host $EventArgs.Text
}

# Now just call any console app, because NativeConsole's going to handle the output
cmd /c "dir && dir brokenthing"

# To get the real output, receive-it
function receive-output {
    Receive-Job $ConsoleOutput, $ConsoleError
}
