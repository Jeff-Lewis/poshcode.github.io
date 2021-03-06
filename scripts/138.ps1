## Depends on the PoshXmpp.dll from http://CodePlex.com/PoshXmpp
#requires -pssnapin PoshXmpp
##########################################################################################
# @Author: Joel Bennnett
# @Usage:
# Start-JabberMirror.ps1 User@JabberServer.com Password "groupchat@oneserver.com" "groupchat@anotherserver.com" "BridgeBot" "http://rssfeed"
##########################################################################################

param (
   $JabberId    =   $(Read-Host "Jabber Login")
   ,$Password   =   $(Read-Host "Password")
   ,$IRC        = "powershell%irc.freenode.net@irc.im.flosoft.biz" # $(Read-Host "First Jabber conference address")
   ,$JabberConf = "powershell@conference.im.flosoft.biz"           # $(Read-Host "Second Jabber conference address")
   ,$ChatNick   = "PowerBot"                                       # $(Read-Host "The nickname you want to use")
   ,[string[]]$AtomFeeds = @("http://groups.google.com/group/microsoft.public.windows.powershell/feed/atom_v1_0_topics.xml")
)
## Requires System.Web for the RSS-feed option
[Reflection.Assembly]::LoadWithPartialName("System.Web") | Out-Null


function Start-PowerBot {
   $global:LastNewsCheck = $([DateTime]::Now.AddHours(-5))
   $global:feedReader = new-object Xml.XmlDocument
   $global:PoshXmppClient = PoshXmpp\New-Client $JabberId $Password # http://im.flosoft.biz:5280/http-poll/
   PoshXmpp\Connect-Chat $IRC $ChatNick
   PoshXmpp\Connect-Chat $JabberConf $ChatNick

   PoshXmpp\Send-Message $IRC "Starting Mirror to $('{0}@{1}' -f $JabberConf.Split(@('%','@'),3))"
   PoshXmpp\Send-Message $JabberConf "Starting Mirror to $('{0}@{1}' -f $IRC.Split(@('%','@'),3))"

   PoshXmpp\Send-Message $IRC "/msg nickserv :id Sup3rB0t"
  
}

function Process-Command($Chat, $Message) {
   $split = $message.Body.Split(" |;")
   $from = $Message.From.Bare.ToLower()
   switch -regex ( $split[0] ) {
      "!list" {
         Write-Host "!LIST COMMAND. Send users of [$Chat] to [$($Message.From.Bare)]" -fore Magenta
         $users = @($PoshXmppClient.ChatManager.GetUsers( $Chat ).Values)
         PoshXmpp\Send-Message $from  ("There are $($users.Count) on $($Chat):")
         PoshXmpp\Send-Message $from  ($users -join ", ")
      }
      "!gh|!get-help|!man" {
         $help = get-help $split[1] | Select Synopsis,Syntax
         $msgs = (get-help $split[1] | ... Synopsis Syntax | Out-String -w 1000 | split-string "`n" -count 4)[0,2];
         PoshXmpp\Send-Message $from $help.Synopsis;
         PoshXmpp\Send-Message $from ($help.Syntax | Out-String -w 1000 | split-string "`n" -count 4 -rem )[1]
      }
   }
}


# Max IRC Message Length http://www.faqs.org/rfcs/rfc1459.html
# PRIVMSG CHANNEL MSG
$IrcMaxLen = 510 - ("PRIVMSG :".Length + $IRC.Length + $JabberId.split('@')[0].Length)

function Get-Feeds([string[]]$JIDs,[string[]]$AtomFeeds) {
   Write-Verbose "Checking feeds..."
   foreach($feed in $AtomFeeds) {
      $feedReader.Load($feed)
      for($i = $feedReader.feed.entry.count - 1; $i -ge 0; $i--) {
         $e = $feedReader.feed.entry[$i]
         if([datetime]$e.updated -gt $global:LastNewsCheck) {
            foreach($jid in $JIDs) {
               $msg = ([System.Web.HttpUtility]::HtmlDecode($e.summary."#text") -replace "<br>", "").Trim()
               $template = "{0} (Posted at {1:hh:mm} by {2}) {{0}} :: {3}" -f
                        $e.title."#text", [datetime]$e.updated, $e.author.name, $e.link.href

               $len = [math]::Min($IrcMaxLen,($template.Length + $msg.Length)) - ($template.Length +3)
               PoshXmpp\Send-Message $jid $($template -f $msg.SubString(0,$len))
            }
            [Threading.Thread]::Sleep( 500 )
         }
      }
   }
   $global:LastNewsCheck = [DateTime]::Now
}

[regex]$anagram = "^Unscramble ... (.*)$"

function Bridge {
   PoshXmpp\Receive-Message -All | foreach-object {
      Write-Verbose ("MESSAGE: FROM[{0}] RESOURCE[{1}] BODY[{2}]"  -f $_.From.Bare, $_.From.Resource, $_.Body)
      if( $_.Type -eq "Error" ) {
         Write-Error $_.Error
      }
      if( $_.From.Resource -ne $ChatNick ) {
         $Chat = $null;
         if( $_.From.Bare -eq $IRC ) 
         {
            $Chat = $JabberConf;
         }
         elseif( $_.From.Bare -eq $JabberConf ) 
         {
            $Chat = $IRC;
         }
         else
         {
            $_
         }

         if($Chat){
            if(![String]::IsNullOrEmpty($_.Body) -and ($_.Body[0] -eq '!')) { 
               PoshXmpp\Send-Message $Chat ("<{0}> {1}" -f $_.From.Resource, $_.Body)
               Process-Command $Chat $_ 
            } 
            elseif(($_.From.Resource -eq "GeoBot") -and $_.Body.StartsWith("Unscramble ... "))
            {
               Write-Verbose "KILL ANAGRAM! $($anagram.Match($_.Body).Groups[1].value)"
               $answers = Solve-Anagram $($anagram.Match($_.Body).Groups[1].value)
               foreach($ans in $answers) {
                  Write-Verbose "ANAGRAM: $($_.From.Bare) $ans"
                  PoshXmpp\Send-Message "$($_.From.Bare.ToLower())" "$ans (PowerShell Scripting FTW!)"
               }
            }
            elseif( ![String]::IsNullOrEmpty($_.Subject) ) 
            {
               $_.To = $Chat
               # Send it directly using a method on the PoshXmppClient
               $PoshXmppClient.Send($_)
            }
            else 
            {
               PoshXmpp\Send-Message $Chat ("<{0}> {1}" -f $_.From.Resource, $_.Body)
            }
         }
      }
   }
}


function Start-Bridge {
   "PRESS ANY KEY TO STOP"
   while(!$Host.UI.RawUI.KeyAvailable) {
      Bridge
      Get-Feeds @($IRC,$JabberConf) $AtomFeeds
      $counter = 0
      Write-Verbose "PRESS ANY KEY TO STOP" # we're going to wait 3 * 60 seconds
      while(!$Host.UI.RawUI.KeyAvailable -and ($counter++ -lt 1800)) {
         Bridge
         [Threading.Thread]::Sleep( 100 )
      }
   }
}

function Stop-PowerBot {
   PoshXmpp\Disconnect-Chat $IRC $ChatNick
   PoshXmpp\Disconnect-Chat $JabberConf $ChatNick
   $global:PoshXmppClient.Close();
}

##
## Silly anagram spoiler
##
function Solve-Anagram($anagram) {
   [xml]$form = Post-HTTP "http://www.anagramsolver.net/Default.aspx" ""

   [xml]$result = Post-HTTP "http://www.anagramsolver.net/Default.aspx" (
   "{0}&{1}&{2}&btnAnagram=Anagram"  -f "txtAnagram=$anagram", 
   ("__VIEWSTATE={0}" -f $($form.SelectSingleNode("//*[@id='__VIEWSTATE']").value)),
   ("__EVENTVALIDATION={0}" -f $($form.SelectSingleNode("//*[@id='__EVENTVALIDATION']").value)))
   
   $result.SelectSingleNode("//*[@id='lblResult']")."#text"
}

function Post-HTTP($url,$bytes) {
   $request = [System.Net.WebRequest]::Create($url)
   #$bytes = [Text.Encoding]::UTF8.GetBytes( $post )
   $request.ContentType = "application/x-www-form-urlencoded"
   $request.ContentLength = $bytes.Length
   $request.Method = "POST"
   $rq = new-object IO.StreamWriter $request.GetRequestStream()
   $rq.Write($bytes,0,$bytes.Length)
   $rq.Close()
   $response = $request.GetResponse()
   $reader = new-object IO.StreamReader $response.GetResponseStream(),[Text.Encoding]::UTF8
   return $reader.ReadToEnd()
}

