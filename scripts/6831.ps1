# encoding: utf-8
# api: ps
# type: functions
# category: data
# title: ConvertTo-PS1
# description: Transform nested hashtable into Powershell-literal (string)
# version: 0.5
# status: beta
# license: MITL
#
# Workaround implementation due to lack of ConvertTo/From-Json in PS 2.0.
# Useful to create a speedier cache, e.g. after extracting Excel files.
# Outfiles can be read in with `$hash = (. ./data/cachefn.ps1)` simply.
#
#  · Only covers strings, integers, and hashtables
#  · REALLY REALLY crude string filtering
#  · Just didn't want to use less legible @'…'@
#  · Definitely NOT SAFE to use on arbitrary input


#-- Transform nested hashtable into Powershell-literal (string)
function ConvertTo-PS1() {
    param($hash, $indent="", $depth=100, $CRLF="`r`n", $Q="'", $v2=@{})
    $sub = $indent + "    "
    switch ($hash.GetType().Name) {
        Int32 {}
        Double {}
        String { $hash = $Q + ($hash -replace "[''’’``‘‘&#8219;&#8219;]","·") + $Q }
        PSCustomObject {
            $hash.PSObject.Properties | ? { $_.Name } | % { $v2[$_.Name] = $_.Value }
            $hash = ConvertTo-PS1 $v2 $indent
        }
        Hashtable {
            $hash = "@{$CRLF" + (($hash.keys | % {
                $sub + (ConvertTo-PS1 $_ $sub) + " = " + (ConvertTo-PS1 $hash[$_] $sub)
            }) -join ";$CRLF") + "$CRLF$indent}"
        }
        default { $hash = "$Q$value$Q"; }
    }
    return "$hash"
}

