$Script:xhtmlns = @{x="http://www.w3.org/1999/xhtml"}
$Script:Definitions = @{}
$Script:LastWord = ""
$Script:LastDefinitionIndex = 0

function Get-Definition {
   #.SYNOPSIS
   #  Gets the definition of a word from dictionary.cambridge.org
   [CmdletBinding(DefaultParameterSetName="NoData")]
   PARAM(
      # The term you want to define
      [Parameter(Position=1, ValueFromRemainingArguments=$true, ValueFromPipeline=$true)]
      [string[]]$term,
      [int]$index
   )
   process {
      foreach($word in $term) {
         $word = $word.ToLower()
         if(!$Definitions.ContainsKey($word)) {
            Write-Verbose "Definition not found for $word, looking up in oxforddictionaries"
            # Invoke-Http GET "http://dictionary.cambridge.org/learnenglish/results.asp" @{searchword="$term" } | 
            #    Receive-Http text "//span[@class='def-classification' or @class='cald-definition']"
            $Xml = Invoke-Http GET "http://www.oxforddictionaries.com/definition/english/$word" | Receive-Http XML
            $Script:Definitions.$word = Select-Xml -Xml $xml -XPath "//x:ul[@class='sense-entry']//x:li[1]//x:span[@class='definition']" -Namespace $xhtmlns | 
               ForEach-Object { $_.Node } | 
               Select-Object @{n="Definition";e={$_."#text".trim(" :")}}, 
                             @{n="partOfSpeech";e={ Select-Xml ".//ancestor::x:section/x:h3/x:span/text()" $_ -Namespace $xhtmlns }}
         }
         if($PSBoundParameters.ContainsKey("index") -or $Script:lastword -ne $word) {
            $Script:LastDefinitionIndex = $index
         }
         if(@($Definitions.$word).Count -le $Script:LastDefinitionIndex) {
            $Script:LastDefinitionIndex = 0
         }
         Write-Verbose "Definition: $LastDefinitionIndex of $(@($Script:Definitions.$word).Count) for $lastword"

         "{0}, {1} ({2} of {3})" -f @($Script:Definitions.$word)[$Script:LastDefinitionIndex].partOfSpeech, @($Script:Definitions.$word)[$Script:LastDefinitionIndex].definition, ($Script:LastDefinitionIndex + 1), @($Script:Definitions.$word).Count
         
         $Script:lastword = $word
         $Script:LastDefinitionIndex += 1
      }
   }
}

