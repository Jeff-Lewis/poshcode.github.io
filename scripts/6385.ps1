#Programmer Name: Nathan Estell
#Date: 8/14/2015
#Description: Displays a constant stream of random colors with random size. This causes patterns to form and can be mesmerizing :)
for (;;)
{
	$r = get-random -max 15
	$r2= get-random -max 15
#[int]$firstDigitRN=$randomNumber[0]
<# Possible way of implementing spaces with loop
for ($i=0;$i -lt $firstDigitRN;$i++)
{
" " | write-host -backgroundcolor $backGroundColor -foregroundcolor $foreGroundColor -NoNewLine
}
#>
	#Deciding the color
	switch ($r)
	{
		0 { $backGroundColor = "Gray"}
		1 { $backGroundColor = "Blue"}
		2 { $backGroundColor = "Green"}
		3 { $backGroundColor = "Cyan"}
		4 { $backGroundColor = "Red"}
		5 { $backGroundColor = "Magenta"}
		6 { $backGroundColor = "Yellow"}
		7 { $backGroundColor = "White"}
		8 { $backGroundColor = "Black"}
		9 { $backGroundColor = "DarkBlue"}
		10 { $backGroundColor = "DarkGreen" }
		11 { $backGroundColor = "DarkCyan" }
		12 { $backGroundColor = "DarkRed" }
		13 { $backGroundColor = "DarkMagenta" }
		14 { $backGroundColor = "DarkYellow" }
		15 { $backGroundColor = "DarkGray" }
	}
	#Implementing the spaces with switch statements
	
	switch ($r2)
	{
		0 { "" | write-host -backgroundcolor $backGroundColor -NoNewLine}
		1 { " " | write-host -backgroundcolor $backGroundColor -NoNewLine}
		2 { "  " | write-host -backgroundcolor $backGroundColor -NoNewLine}
		3 { "   " | write-host -backgroundcolor $backGroundColor -NoNewLine }
		4 { "    " | write-host -backgroundcolor $backGroundColor -NoNewLine }
		5 { "     " | write-host -backgroundcolor $backGroundColor -NoNewLine }
		6 { "      " | write-host -backgroundcolor $backGroundColor -NoNewLine }
		7 { "       " | write-host -backgroundcolor $backGroundColor -NoNewLine }
		8 { "        " | write-host -backgroundcolor $backGroundColor -NoNewLine }
		9 { "         " | write-host -backgroundcolor $backGroundColor -NoNewLine }
		10 { "          " | write-host -backgroundcolor $backGroundColor -NoNewLine }
		11 { "           " | write-host -backgroundcolor $backGroundColor -NoNewLine }
		12 { "            " | write-host -backgroundcolor $backGroundColor -NoNewLine }
		13 { "             " | write-host -backgroundcolor $backGroundColor -NoNewLine }
		14 { "              " | write-host -backgroundcolor $backGroundColor -NoNewLine }
		15 { "               " | write-host -backgroundcolor $backGroundColor -NoNewLine }
	}
}
