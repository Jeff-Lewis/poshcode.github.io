#requires -Module SQLite

if(!(Test-Path data:)) {
   Mount-SQLite -name data -dataSource data.sqlite
}
if(!(Test-Path data:\FAQ)) {
   new-item data:\FAQ -Value @{ Question="TEXT UNIQUE NOT NULL"; Answer="TEXT NOT NULL" }
   New-FAQ "best powershell books" @"
For beginners: http://powershell.com/cs/blogs/ebook/ (Free) or Don's Month of Lunches book http://j.mp/1kEBG3z
For intermediate: PowerShell Toolmaking http://j.mp/1i29RAh More Free eBooks http://j.mp/1m9deTr
For experts: PowerShell In Action http://www.manning.com/payette2/
For developers: Doug's PowerShell for Developers http://j.mp/1dhUwXO, best powershell books
"@   
}


function New-FAQ { 
   #.Synopsis
   #  Adds a question and answer to the FAQ list
   param(
      # A short question
      [Parameter(Mandatory,Position=0)]
      [String]$Question,

      # Less than five lines of answer
      [Parameter(Mandatory,Position=1,ValueFromPipeline)]
      [String[]]$Answer
   )
   begin { 
      $Question = $Question.ToLowerInvariant() -replace "[^\p{L} ]"
      $FullAnswer = "" 
   }
   process { $FullAnswer = @(@($FullAnswer) + $Answer) -Join "`n" }
   end {
      $Result = New-Item data:\FAQ -Question $Question -Answer $FullAnswer -ErrorAction SilentlyContinue -ErrorVariable Failed
      if($Failed) {
         Write-Warning $($Failed.Exception.Message -split "[\r\n]+" -join ": ")
      } else {
         "Added: {0}" -f $Result.Question
      }
   }
}

function Set-FAQ { 
   #.Synopsis
   #  Changes the answer to a question on the FAQ list
   param(
      # A short question
      [Parameter(Mandatory,Position=0)]
      [String]$Question,

      # Less than five lines of answer
      [Parameter(Mandatory,Position=1,ValueFromPipeline)]
      [String]$Answer
   )
   begin { 
      $Question = $Question.ToLowerInvariant() -replace "[^\p{L} ]"
      $FullAnswer = "" 
   }
   process { $FullAnswer = @(@($FullAnswer) + $Answer) -Join "`n" }
   end {
      $Result = Set-Item data:\FAQ -Question $Question -Answer $FullAnswer -ErrorAction SilentlyContinue -ErrorVariable Failed
      if($Failed) {
         Write-Warning $($Failed.Exception.Message -split "[\r\n]+" -join ": ")
      } else {
         "Set: {0}" -f $Result.Question
      }
   }
}

function Get-FAQ {
   #.Synopsis
   #  Returns a specific FAQ (the first one that matches)
   param(
      # A short question
      [Parameter(Position=0,ValueFromPipeline)]
      [String]$Question
   )
   if($Question -as [int]) {
      Get-Item data:\FAQ\$Question | % Answer
   } elseif($Question) {
      $Question = $Question.ToLowerInvariant() -replace "[^\p{L} ]"
      Get-Item -Path data:\FAQ -filter "Question = '${Question}'" | % Answer
   } else {
      "Available FAQs: {0}" -f ((Get-ChildItem -Path data:\FAQ | % Question) -join ", ")
   }
}

Set-Alias FAQ Search-FAQ
function Search-FAQ {
   #.Synopsis
   #  Returns a specific FAQ (the first one that matches)
   param(
      # A short question
      [Parameter(Mandatory,Position=0,ValueFromRemainingArguments,ValueFromPipeline)]
      [String[]]$Question
   )
   [String]$Question = ($Question | % ToLowerInvariant) -join "%" -replace '\*','%' -replace "[^\p{L} %]"
   $FAQs = Get-Item -Path data:\FAQ -filter "Question like '%${Question}%'"
   switch (@($FAQs).Count) {
      1 { $FAQs.Answer }
      0 { "Couldn't find any FAQ matching ${Question}"}
      default { "I found more than one matching question: {0}" -f $(($FAQs | % Question) -join ", ") }
   }   
}

Export-ModuleMember -Function * -Alias *
