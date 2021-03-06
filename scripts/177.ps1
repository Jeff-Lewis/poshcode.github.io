## Pause (aka Pause-Script)
## Pause the script and wait for user action
###################################################################################################
## Parameters (are all OPTIONAL)
##    Message      - the message to use as the prompt to the user
##    ReturnKey    - when present, the script returns the key that was pressed as output
##    LeaveMessage - if not present, the script erases the prompt when it's done
###################################################################################################
param([String]$Message="Press any key to continue...", [Switch]$ReturnKey, [Switch]$LeaveMessage)

## Get the cursor position before writing, we'll set it back here later.
$pos = $Host.UI.RawUI.CursorPosition;
## Flush the input buffer before pausing, just in case
$Host.UI.RawUI.FlushInputBuffer()
Write-Host -NoNewLine:$(!$LeaveMessage) $Message
## Save the key, in case they want it back
$key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp")
if(!$LeaveMessage) {
   ## Overwrite the Message with empty space
   $Host.UI.RawUI.CursorPosition = $pos;
   Write-Host -NoNewLine (" " *$Message.Length)
   ## Set the Cursor back where it started
   $Host.UI.RawUI.CursorPosition = $pos;
}
## And return the key if they want it, otherwise we're done
if($ReturnKey) { return $Key }
