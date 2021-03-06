#requires -version 1.0
# or version 2.0, obviously
## ISO 8601 Dates
########################################################################
## Copyright (c) Joel Bennett, 2009
## Free for use under GPL, MS-RL, MS-PL, or BSD license. Your choice.
function Get-ISODate {
#.Synopsis
#  Get the components of an ISO 8601 date: year, week number, day of week
#.Description
#  For any given date you get an array of year, week, day that you can use
#  as part of a string format....
#.Parameter Date
#  The date you want to analyze. Accepts dates on the pipeline
Param([DateTime]$date=$(Get-Date))
Process {
  if($_){$date=$_}
  ## Get Jan 1st of that year
  $startYear  = Get-Date -Date $date -Month 1 -Day 1 
  ## Get Dec 31st of that year
  $endYear    = Get-Date -Date $date -Month 12 -Day 31 
  ## ISO 8601 weeks are Monday-Sunday, with days marked 1-7
  ## But .Net's DayOfWeek enum is 0 for Sunday through 6 for saturday
  $dayOfWeek  = @(7,1,2,3,4,5,6)[$date.DayOfWeek]
  $lastofWeek = @(7,1,2,3,4,5,6)[$endYear.DayOfWeek]
  ## By definition: the first week of a year is the one which 
  ##           includes the first Thursday, and thus, January 4th
  $adjust     = @(6,7,8,9,10,4,5)[$startYear.DayOfWeek]
  
  switch([Math]::Floor((($date.Subtract($startYear).Days + $adjust)/7)))
  {
    0 {
      ## Return weeknumber of dec 31st of the previous year
      ## But return THIS dayOfWeek
      Write-Output @(
         @(Get-ISODate $startYear.AddDays(-1))[0,1] + @(,$dayOfWeek))
    }
    53 {
      ## If dec 31st falls before thursday it is week 01 of next year
      if ($lastofWeek -lt 4) {
        Write-Output @(($date.Year + 1), 1, $dayOfWeek)
      } else {
        Write-Output @($date.Year, $_, $dayOfWeek)
      }
    }
    default { 
      Write-Output @($date.Year, $_, $dayOfWeek)
    }
  }
}
}

function Get-ISOWeekOfYear {
#.Synopsis
#  Get the correct (according to ISO 8601) week number
#.Description
#  For any given date you get the week of the year, according to ISO8610
#.Parameter Date
#  The date you want to analyze. Accepts dates on the pipeline
Param([DateTime]$date=$(Get-Date))
Process {
  if($_){$date=$_}
  @(Get-ISODate $date)[1]
}
}

function Get-ISOYear {
#.Synopsis
#  Get the correct (according to ISO 8601) year number
#.Description
#  For any given date you get the year number, according to ISO8610 ...
#  for some days at the begining or end of year, it reports the previous
#  or the next year (because ISO defines those days as part of the first
#  or last week of the adjacent year).
#.Parameter Date
#  The date you want to analyze. Accepts dates on the pipeline
Param([DateTime]$date=$(Get-Date))
Process {
  if($_){$date=$_}
  @(Get-ISODate $date)[0]
}
}

function Get-ISODayOfWeek {
#.Synopsis
#  Get the correct (according to ISO 8601) day of the week
#.Description
#  For any given date you get the day of the week, according to ISO8610
#.Parameter Date
#  The date you want to analyze. Accepts dates on the pipeline
Param([DateTime]$date=$(Get-Date))
Process {
  if($_){$date=$_}
  @(7,1,2,3,4,5,6)[$date.DayOfWeek]
}
}

function Get-ISODateString {
#.Synopsis
#  Get the correctly formatted (according to ISO 8601) date string
#.Description
#  For any given date you get the date string, according to ISO8610, 
#  like: 2009-W12-4  for Thursday, March 19th, 2009
#.Parameter Date
#  The date you want to analyze. Accepts dates on the pipeline
Param([DateTime]$date=$(Get-Date))
Process {
  if($_){$date=$_}
  "{0}-W{1:00}-{2}" -f @(Get-ISODate $date)
}
}

function ConvertFrom-ISODateString {
#.Synopsis
#  Parses ISO 8601 Date strings in the format: 2009-W12-4 to DateTime
#.Description
#  Allows converting ISO-formated date strings back into actual objects
#.Parameter Date
#  An ISO8601 date, like:
#    2009-W12-4 for Thursday, March 19th, 2009
#    1999-W52-6 for Saturday, January 1st, 2000
#    2000-W01-1 for Monday, January 3rd, 2000
Param([string]$date)
Process {
  if($_){$date=$_}
  if($date -notmatch "\d{4}-W\d{2}-\d") {
    Write-Error "The string is not an ISO 8601 formatted date string"
  }
  $ofs = ""
  $year = [int]"$($date[0..3])"
  $week = [int]"$($date[6..7])"
  $day  = [int]"$($date[9])"

  $firstOfYear = Get-Date -year $year -day 1  -month 1
  $days = 7*$week - ((Get-ISODayOfWeek $firstOfYear) - $day)
 
  $result = $firstOfYear.AddDays( $days )
  if(($result.Year -ge $year) -and ((Get-ISODayOfWeek $firstOfYear) -le 4) ) {
   return $firstOfYear.AddDays( ($days - 7) )
  } else {
   return $result
  }
}
}


