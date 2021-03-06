Clear
# Draw a vertical line on the right side of the console window
    $position = $Host.UI.RawUI.CursorPosition
    $height = $Host.UI.RawUI.WindowSize.height
    $bottom = ($height - 2)
For($y=2; $y -lt $bottom; $y++){
    $position.x = ($Host.UI.RawUI.WindowSize.width - 5) # Horizontal position
    $position.y = $y # Vertical position
    $Host.UI.RawUI.CursorPosition = $position
    $vertchar = [char]9553
Write-Host $vertchar}

# Create a point on the line
    $point = Get-Random -Minimum 3 $bottom
    $position.y = $point
    $Host.UI.RawUI.CursorPosition = $position
    $pointchar = [char]9571
Write-Host $pointchar

# User input to guess the position of the point
    $position.x = 0
    $position.y = ($height-2)
    $Host.UI.RawUI.CursorPosition = $position
    $btmPos = ($bottom - 1)
$guess = Read-Host "Guess where the point is (between 2 and $btmPos)"

# Draw a horizontal line at the point of the guess
    $horizChar = [char]9552
    $eraseChar = [char]32
    $width = $Host.UI.RawUI.WindowSize.width
For($x=0; $x -lt ($width - 5); $x++){
    $position = $Host.UI.RawUI.CursorPosition
    $position.x = $x
    $position.y = $guess
    $Host.UI.RawUI.CursorPosition = $position
Write-Host $horizChar
sleep -Milliseconds 25

# Reset the horizontal character two spaces behind the current position
    $erase = $x - 1
    If($erase -gt 0){$position.x = $erase}
    $Host.UI.RawUI.CursorPosition = $position
Write-Host $eraseChar}

# Show point location
    $position.x = ($width - 3)
    $position.y = $point
    $Host.UI.RawUI.CursorPosition = $position
If($guess -eq $point) {Write-Host $point -ForegroundColor Green}
    Else {Write-Host $point -ForegroundColor Red}

# Indicate win or lose and query for another round
    $position.x = 0
    $Host.UI.RawUI.CursorPosition = $position
If($guess -eq $point) {Write-Host "   WINNER!" -ForegroundColor Green}
    Else {Write-Host " $guess is a LOSER" -ForegroundColor Red}
$repeat = Read-Host " Again (y/n)"
If($repeat -ne "n" -or $repeat -ne "N")
    {.\target.ps1}
Else{Exit}

