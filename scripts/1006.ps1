<#
.Synopsis
    Makes a baloon tip in the notification area
.Description
    With just a few arguments, it is easy to make some text appear in a little balloon.
    
    You can specify an icon file (*.ico) with the -icon argument, if you don't then 
    the first icon of the host is used.
    
    out-balloon accepts pipeline input, strings only please.
    
    It blocks for the duration of the balloon display, 3 seconds by default.  Simple
    fixes for this are welcome.
    
    timeout should be an integer value.
    
    INSTALLATION:
        um, save this text in a file named out-balloon.ps1 in your path
        
.Example
    out-balloon "hey, your job is done." -icon "C:\Program Files\Microsoft Office\Office12\MYSL.ICO"
    
    "job done." | out-balloon
#>    
param(
    [Parameter(ValueFromPipeline=$true,Position=0,Mandatory=$true)]
    [Alias('output')]
    [string]$text,
    [string]$icon,
    [int32]$timeout = 3
    )
begin
{
    
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

    $not = new-object System.Windows.Forms.NotifyIcon
    if ($icon -eq $null)
    {
        if ($win32extraciconex -eq $null)
        {
            $script:ExtractIconEx = Add-Type –memberDefinition @"
                [DllImport("Shell32", CharSet=CharSet.Auto)]
                private static extern int ExtractIconEx (string lpszFile, int nIconIndex,
                    IntPtr[] phIconLarge,IntPtr[] phIconSmall,int nIcons);

                [DllImport("user32.dll", EntryPoint="DestroyIcon", SetLastError=true)]
                private static extern int DestroyIcon(IntPtr hIcon);

                public static System.Drawing.Icon ExtractIconFromExe(string file, bool large)
                {
                    int readIconCount = 0;
                    IntPtr[] hDummy  = new IntPtr[1] {IntPtr.Zero};
                    IntPtr[] hIconEx = new IntPtr[1] {IntPtr.Zero};

                    try
                    {
                        if(large)
                            readIconCount = ExtractIconEx(file,0, hIconEx, hDummy, 1);
                        else
                            readIconCount = ExtractIconEx(file,0, hDummy, hIconEx, 1);

                        if(readIconCount > 0 && hIconEx[0] != IntPtr.Zero)
                        {
                            System.Drawing.Icon extractedIcon = (System.Drawing.Icon)System.Drawing.Icon.FromHandle(hIconEx[0]).Clone();
                            return extractedIcon;
                        }
                        else // NO ICONS READ
                            return null;
                    }
                    catch(Exception ex)
                    {
                        throw new ApplicationException("Failed extracting icon", ex);
                    }
                    finally
                    {
                        foreach(IntPtr ptr in hIconEx)
                        if(ptr != IntPtr.Zero)
                            DestroyIcon(ptr);

                        foreach(IntPtr ptr in hDummy)
                        if(ptr != IntPtr.Zero)
                            DestroyIcon(ptr);
                    }
                
                }
"@  -name “Win32ExtractIconEx” -namespace win32api –passThru -ReferencedAssemblies "System.Drawing"
        }

        $not.Icon = $extractIconEx::ExtractIconFromExe((get-process -Id $pid).mainmodule.filename, $true)
    }
    else
    {
        $not.Icon = new-object System.Drawing.Icon($icon)
    }
    $not.visible = $true
}
process
{

    $not.BalloonTipText = $text
    $not.ShowBalloonTip($timeout)
    sleep $timeout
}
end
{
    $not.dispose()
}


