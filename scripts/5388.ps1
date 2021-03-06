@@# 1. signin to your tripit account
@@# 2. click on "Trips" on top
@@# 3. click on "Calendar integration" in the left pane
@@# 4. click on "Subscribe to calendar feed"
@@# 5. copy the link to the .ics file and paste it below


$PRIVATETRIPITURL="http://www.tripit.com/feed/ical/private/DEADBEEF-00001111222AEAEAEFBFBF333AAA000D/tripit.ics"


$clnt = new-object System.Net.WebClient; 
$clnt.DownloadFile($PRIVATETRIPITURL, "$env:temp\tripit.ics");
$icsfile="$env:temp\tripit.ics"
$filename = "$env:temp\tripit.png"

#constants
$CDAYHEIGHT=50
$CDAYWIDTH=100


function dateToXPos
{
    param ([Parameter(Mandatory=$true)] [System.DateTime]$dateParam)
    (([int]($dateParam.DayOfWeek)+6) % 7)    
}

function dateToYPos
{
    param ([Parameter(Mandatory=$true)] [System.DateTime]$dateParam)
    ([math]::Ceiling((($dateParam-$minDate).Days-6)/7))
}


$icstable=@(@(),@(),@(),@())

$icscontent = Get-Content $icsfile -Encoding UTF8
$minFileDate='9999';
$maxFileDate='0';
ForEach ($icsline in $icscontent)
{
    if ($icsline.StartsWith("BEGIN:VEVENT"))
    {
        $entryGEO="";
        $entryDTSTART="";
        $entryDTEND="";
        $entrySUMMARY="";
        continue;
    }
    #DTEND:20140502T193500Z
    if ($icsline.StartsWith("DTEND:"))
    {
        $entryDTEND=$icsline.Split(':')[1].Trim();
        if ($entryDTEND -gt $maxFileDate)
        {
            $maxFileDate=$entryDTEND;
        }
        continue;
    }

    #DTSTART:20140401T043000Z
    if ($icsline.StartsWith("DTSTART:"))
    {
        $entryDTSTART=$icsline.Split(':')[1].Trim();
        if ($entryDTSTART -lt $minFileDate)
        {
            $minFileDate=$entryDTSTART;
        }
        continue;
    }

    #GEO:33.15;22.583333
    if ($icsline.StartsWith("GEO:"))
    {
        $entryGEO=$icsline.Split(':')[1].Trim();
        continue;
    }

    #SUMMARY:LO354 MUC to WAW
    if ($icsline.StartsWith("SUMMARY:"))
    {
        if (($icsline.Split(':')[2]) -eq $null) 
        {
            $entrySUMMARY=$icsline.Split(':')[1].Trim();
        }
        continue;
    }

    if ($icsline.StartsWith("END:VEVENT"))
    {
        if (($entryDTSTART -ne "") -and ($entryDTEND -ne "") -and ($entrySUMMARY -ne "") -and ($entrySUMMARY.Length -le 20))
        {
            $arr=$entryDTSTART,$entryDTEND,$entrySUMMARY,"";
            $icstable += $arr
        }
        continue;
    }
}


$minFileDate=$minFileDate.Split('T')[0];
$maxFileDate=$maxFileDate.Split('T')[0];
$minDate=([datetime]::ParseExact($minFileDate,"yyyyMMdd",$null)).AddDays(-1);
$maxDate=([datetime]::ParseExact($maxFileDate,"yyyyMMdd",$null)).AddDays(1);

$minDate=$minDate.AddDays(-[int]$minDate.DayOfWeek+1)
if ([int]$maxDate.DayOfWeek -ne 0)
{
    $maxDate=$maxDate.AddDays(7-[int]$maxDate.DayOfWeek)
}



$bmp = new-object System.Drawing.Bitmap (9*$CDAYWIDTH), ($CDAYHEIGHT*([math]::Ceiling(($maxDate-$minDate).Days/7)+2))
$font = new-object System.Drawing.Font Consolas,24 
$brushFg = [System.Drawing.Brushes]::Black 
$brushBg = [System.Drawing.Brushes]::AliceBlue 
$graphics = [System.Drawing.Graphics]::FromImage($bmp) 
$graphics.FillRectangle($brushBg,0,0,$bmp.Width,$bmp.Height) 


$font = new-object System.Drawing.Font Consolas,7
$dayoffset=2

for ($i=$minDate; $i -le $maxDate; $i=$i.AddDays(1))
{
    $dateString=$i.ToString('dd MMM')
    $boxx=dateToXPos($i)
    $boxy=dateToYPos($i)
    $graphics.DrawRectangle($brushFg, ($boxx+1)*$CDAYWIDTH,($boxy+1)*$CDAYHEIGHT,$CDAYWIDTH, $CDAYHEIGHT)
    $graphics.DrawString($dateString,$font,$brushFg,($boxx+1)*$CDAYWIDTH,($boxy+1)*$CDAYHEIGHT) 
}


$d1p=0;
$d1po=0;
for ($i=0; $i -lt $icstable.Count/4; $i++)
{

    if ($icstable[$i*4]) #not null or empty
    {

        $d1=(($icstable[$i*4]).ToString()).Substring(0,8);
        $d1=[datetime]::ParseExact($d1,"yyyyMMdd",$null);
        $boxx=dateToXPos($d1)
        $boxy=dateToYPos($d1)
        if ($d1p -eq $d1)
        {
            $d1po++
        }
        else
        {
            $d1p=$d1
            $d1po=0
        }

        $dispStr=$icstable[$i*4+2]
        $dispStr1=$dispStr.Split(' ')[0];
        $dispStr2=$dispStr.Split(' ')[1..4];

        while ($dispStr1.Length -lt 7)
        {
            $dispStr1=$dispStr1+' '
        }

        $dispStr=$dispStr1+$dispStr2
        $graphics.DrawString($dispStr,$font,$brushFg,($boxx+1)*$CDAYWIDTH+5,($boxy+1)*$CDAYHEIGHT+10+10*$d1po) 
    }
}




$graphics.Dispose() 
$bmp.Save($filename) 

Invoke-Item $filename

