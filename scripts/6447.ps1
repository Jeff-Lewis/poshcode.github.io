$folder1 = "C:\Users\Ciphr\Desktop\Test\738"
        $folder2 = "C:\Users\Ciphr\Desktop\Test\740"


        # Get all files under $folder1, filter out directories
        $firstFolder = Get-ChildItem -Recurse $folder1 | Where-Object { -not $_.PsIsContainer }

        $failedCount = 0
        $i = 0
        $totalCount = $firstFolder.Count
        $firstFolder | ForEach-Object {
            $i = $i + 1
            Write-Progress -Activity "Searching Files" -status "Searching File  $i of     $totalCount" -percentComplete ($i / $firstFolder.Count * 100)
            # Check if the file, from $folder1, exists with the same path under $folder2
            If ( Test-Path ( $_.FullName.Replace($folder1, $folder2) ) ) {
                # Compare the contents of the two files...
                If ( Compare-Object (Get-Content $_.FullName) (Get-Content $_.FullName.Replace($folder1, $folder2) ) ) {
                    # List the paths of the files containing diffs
                    $fileSuffix = $_.FullName.TrimStart($folder1)
                    $failedCount = $failedCount + 1
                    Write-Host "$fileSuffix is on each server, but does not match"
                }
            }
            else
            {
                $fileSuffix = $_.FullName.TrimStart($folder1)
                $failedCount = $failedCount + 1
                Write-Host "$fileSuffix is only in folder 1"
$fileSuffix | Out-File "$env:userprofile\desktop\Old version.txt" -Append
            }
        }

        $secondFolder = Get-ChildItem -Recurse $folder2 | Where-Object { -not $_.PsIsContainer }

        $i = 0
        $totalCount = $secondFolder.Count
        $secondFolder | ForEach-Object {
            $i = $i + 1
            Write-Progress -Activity "Searching for files only on second folder" -status "Searching File  $i of $totalCount" -percentComplete ($i / $secondFolder.Count * 100)
            # Check if the file, from $folder2, exists with the same path under $folder1
            If (!(Test-Path($_.FullName.Replace($folder2, $folder1))))
            {
                $fileSuffix = $_.FullName.TrimStart($folder2)
                $failedCount = $failedCount + 1
                Write-Host "$fileSuffix is only in folder 2"
$fileSuffix | Out-File "$env:userprofile\desktop\folder2.txt" -Append
            }
        }
