<#
.Synopsis
   Import Exchange 2010 Gal photo for one or more users. 
.DESCRIPTION
   This function invokes the Import-RecipientDataProperty cmdldet to import a picture into the thumbnailPhoto attribute of an Exchange mailbox.
   It assumes you have a directory containing all images to import, with the file names corresponding to the usernames of the mailboxes.
   
   PS X:\> dir *.jpg


        Directory: c:\temp\pics


    Mode                LastWriteTime     Length Name
    ----                -------------     ------ ----
    -a---        07.08.2012     19:29       5984 user1.name.jpg
    -a---        16.05.2012     11:58       5984 user2.jpg
    -a---        23.07.2012     15:55       5984 user3.name.jpg
    ...

.EXAMPLE
   PS C:\> Import-GalPhoto -FilePath 'c:\temp\pics'
   This example gets all .jpg pictures from c:\temp\pics and tries to find corresponding Exchange Users. If a user is found, the picture is imported using Import-RecipientDataProperty.
.EXAMPLE
   PS C:\> dir 'c:\temp\pics' | Select-Object -First 2 | Import-GalPhoto
   This example shows how you can use Get-ChildItem (dir) and do some custom filtering (Where-Object, Select-Object) to get pictures. 
   Then it makes use of pipeline input to import pictures.
#>
function Import-GalPhoto
{
    [CmdletBinding(SupportsShouldProcess=$true, 
                  ConfirmImpact='High')]
    Param
    (
        # Set the FilePath where pictures are located
        [Parameter(Mandatory=$true, 
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [Alias('FullName')]
        [IO.FileInfo]
        $FilePath,

        # LogFile set the destination for LogFile, defaults to ".\Import-GalPhoto.txt" 
        [Parameter(Mandatory=$false,
                   ParameterSetName='Parameter Set 1')]
        $LogFile=".\Import-GalPhoto.txt"
    )

    Begin
    {
        Write-Verbose 'Execute Begin Block'
        # delete LogFile
        Remove-Item $LogFile -ErrorAction SilentlyContinue
        
        # load assembly, used to get Image Properties
        [void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

        # logging
        "$(Get-Date) Function begin" | Add-Content -Path $LogFile -WhatIf:$false
    }
    Process
    {
        Write-Verbose 'Execute Process Block'

        # create an array that contains all files
        [array]$arrPics = Get-ChildItem -Path $FilePath -File -Filter '*.jpg'
        "$(Get-Date) arrPics is $($arrPics)" | Add-Content -Path $LogFile -WhatIf:$false

        $arrPics | ForEach-Object {
            # objPicture contains full path to the picture
            [IO.FileInfo]$objPicture = $_.FullName
            
            # assume file BaseName equals UserName
            [string]$strUserName = $_.BaseName
            
            # logging
            Write-Verbose "`$objPicture is $objPicture"
            Write-Verbose "`$strUserName is $strUserName"
            "$(Get-Date) objPicture is $($objPicture)" | Add-Content -Path $LogFile -WhatIf:$false
            "$(Get-Date) strUserName is $($strUserName)" | Add-Content -Path $LogFile -WhatIf:$false
    
            # some verification before manipulating stuff
            try {
                Write-Verbose "Try to find User $strUserName"
                Start-Sleep -Seconds 1
                $exchangeUser = Get-User -Identity $strUserName -ErrorAction Stop
                $Continue = $true

                # get Image Properties
                $objImage = [System.Drawing.Image]::FromFile($objPicture)

                # get content from image file, used with Import-RecipientDataProperty
                $objFileData = ([Byte[]]$(Get-Content -Path $objPicture -Encoding Byte -ReadCount 0 -ErrorAction Stop))
                    
                # logging
                Write-Verbose "`$exchangeUser is $($exchangeUser.SamAccountName)"
                Write-Verbose "`$objImage PhysicalDimensionis is $($objImage.PhysicalDimension)"
                Write-Verbose "`$objPicture filesize(KB) is $($objPicture.Length / 1kb)"
                "$(Get-Date) exchangeUser is $($exchangeUser.SamAccountName)" | Add-Content -Path $LogFile -WhatIf:$false
                "$(Get-Date) Image PhysicalDimension is $($objImage.PhysicalDimension)" | Add-Content -Path $LogFile -WhatIf:$false
                "$(Get-Date) Image filesize(KB) is $($objPicture.Length / 1kb)" | Add-Content -Path $LogFile -WhatIf:$false

            } catch {
                $Continue = $false

                # logging
                Write-Warning "Could not find User $strUserName"
                "$(Get-Date) Could not find $($strUserName)" | Add-Content -Path $LogFile -WhatIf:$false
            }
            
            # use objImage to check if image size is ok, max 96x96 pixels, max 10K
            if ($Continue -and (($objImage.Height -le 96) -and ($objImage.Width -le 96) -and ($objPicture.Length -le 10kb))){
                $Continue = $true

                # get rid of objImage
                $objImage.Dispose()                

                # logging
                Write-Verbose "Picture $($objPicture) is ok"
            } else {
                $Continue = $false
                
                # logging
                Write-Verbose "Picture $($objPicture) is not ok"
                "$(Get-Date) Skipped $($objPicture) size not ok" | Add-Content -Path $LogFile -WhatIf:$false
            }
                    
            # if verification is ok, go ahead and import images
            if ($Continue -and ($pscmdlet.ShouldProcess("$($exchangeUser.SamAccountName)", "Importing Recipient Data Property from file $objPicture"))) {
                
                # invoke Import-RecipientDataProperty to import data into active directory
                Import-RecipientDataProperty -Identity $exchangeUser.Identity -Picture -FileData $objFileData    
            }
        }
    }
    End
    {
        Write-Verbose 'Execute End Block'
        
        # logging
        "$(Get-Date) Function end" | Add-Content -Path $LogFile -WhatIf:$false
    }
}
