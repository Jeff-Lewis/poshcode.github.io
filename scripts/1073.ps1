##############################################################################
#.AUTHOR
# Josh Einstein
# Einstein Technologies, LLC
##############################################################################

##############################################################################
#.SYNOPSIS
# Opens a new mail message window (without actually sending it) with the 
# To/CC/BCC/Subject/Body pre-filled with optional values and optional file
# attachments added to the message.
#
#.DESCRIPTION
# This function uses your default email client to display a new message
# window with the specified file(s) attached and a pre-filled subject and
# message body.
#
#.PARAMETER Path
# Specifies the path to one or more attachments to add. Wildcards are permitted.
#
#.PARAMETER LiteralPath
# Specifies the path to an item. Unlike Path, the value of LiteralPath is
# used exactly as it is typed. No characters are interpreted as wildcards.
# If the path includes escape characters, enclose it in single quotation marks.
# Single quotation marks tell Windows PowerShell not to interpret any
# characters as escape sequences.
#
#.PARAMETER To
# Specifies one or more recipients on the To line.
#
#.PARAMETER CC
# Specifies one or more recipients on the CC line.
#
#.PARAMETER BCC
# Specifies one or more recipients on the BCC line.
#
#.PARAMETER Subject
# The subject of the message.
#
#.PARAMETER Body
# The body of the message.
#
#.EXAMPLE
# Get-ChildItem C:\temp\*.txt | Send-MAPI -To josheinstein@hotmail.com
##############################################################################
function Send-MAPI {

    [CmdletBinding(DefaultParameterSetName='Path')]
    param(
    
        [Parameter(ParameterSetName='Path', Position=1, Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [String[]]$Path,
        
        [Alias("PSPath")]
        [Parameter(ParameterSetName='LiteralPath', Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [String[]]$LiteralPath,
        
        [Parameter()]
        [String[]]$To,
        
        [Parameter()]
        [String[]]$CC,
        
        [Parameter()]
        [String[]]$BCC,
        
        [Parameter()]
        [String]$Subject,
        
        [Parameter()]
        [String]$Body
        
    )

    begin {
    
        $Message = New-Object MAPI.Message

        $Message.AddRecipient($To)
        $Message.AddCC($CC)
        $Message.AddBCC($BCC)
        $Message.Subject = $Subject
        $Message.Body = $Body
    
    }

    process {
    
        switch ($PSCmdlet.ParameterSetName) {
            Path        { $ResolvedPaths = @(Resolve-Path -Path:$Path) }
            LiteralPath { $ResolvedPaths = @(Resolve-Path -LiteralPath:$LiteralPath) }
        }

        foreach ($ResolvedPath in $ResolvedPaths) {
            Write-Verbose "$($PSCmdlet.MyInvocation.MyCommand.Name) Processing $ResolvedPath"
            $Message.Attachments.Add($ResolvedPath.ProviderPath)
        }

    }
    
    end {
    
        if ($Message.Attachments.Count) {
            if (-not $Message.Subject) { $Message.Subject = "Emailing: $($Message.Attachments | %{ [IO.Path]::GetFileName($_) })" }
            if (-not $Message.Body) {
                $Message.Body = @"
Your message is ready to be sent with the following file or link attachments:
$(($Message.Attachments | %{ [IO.Path]::GetFileName($_) }) -join "`n" )

Note: To protect against computer viruses, e-mail programs may prevent sending or receiving certain types of file attachments.  Check your e-mail security settings to determine how attachments are handled.
"@
            }
        }
        
        $Message.Show()
    
    }

}


Add-Type @"

// Credit goes to David M Brooks
// http://www.codeproject.com/KB/IP/SendFileToNET.aspx

using System;
using System.Collections.Specialized;
using System.Runtime.InteropServices;
using System.IO;
using System.Collections.Generic;
using System.Threading;

namespace MAPI
{
    public sealed class Message
    {
    
        public Message() {
            Attachments = new List<string>();
        }

        public string Subject;
        public string Body;
        public List<string> Attachments;
    
        public void AddRecipient(string[] email)
        {
            if (email == null || email.Length == 0) return;
            foreach ( string e in email) {
                AddRecipient(e, HowTo.MAPI_TO);
            }
        }

        public void AddCC(string[] email)
        {
            if (email == null || email.Length == 0) return;
            foreach ( string e in email ) {
                AddRecipient(e, HowTo.MAPI_TO);
            }
        }

        public void AddBCC(string[] email)
        {
            if (email == null || email.Length == 0) return;
            foreach ( string e in email ) {
                AddRecipient(e, HowTo.MAPI_TO);
            }
        }

        public void Show() {
            Thread t = new Thread((ThreadStart)delegate {
                SendMail(Subject, Body, MAPI_LOGON_UI | MAPI_DIALOG);
            });
            t.SetApartmentState(ApartmentState.STA);
            t.Start();
        }

        public void Send() {
            Thread t = new Thread((ThreadStart)delegate {
                SendMail(Subject, Body, MAPI_LOGON_UI);
            });
            t.SetApartmentState(ApartmentState.STA);
            t.Start();
        }


        [DllImport("MAPI32.DLL")]
        static extern int MAPISendMail(IntPtr sess, IntPtr hwnd, MapiMessage message, int flg, int rsv);

        int SendMail(string strSubject, string strBody, int how)
        {
            MapiMessage msg = new MapiMessage();
            msg.subject = strSubject;
            msg.noteText = strBody;

            msg.recips = GetRecipients(out msg.recipCount);
            msg.files = GetAttachments(out msg.fileCount);

            m_lastError = MAPISendMail(new IntPtr(0), new IntPtr(0), msg, how, 0);
            if (m_lastError > 1)
                throw new Exception("MAPISendMail failed! " + GetLastError());

            Cleanup(ref msg);
            return m_lastError;
        }

        bool AddRecipient(string email, HowTo howTo)
        {
		    MapiRecipDesc recipient = new MapiRecipDesc();

            recipient.recipClass = (int)howTo;
    		recipient.name = email;
		    m_recipients.Add(recipient);

            return true;
        }

        IntPtr GetRecipients(out int recipCount)
        {
            recipCount = 0;
            if (m_recipients.Count == 0)
                return IntPtr.Zero;

            int size = Marshal.SizeOf(typeof(MapiRecipDesc));
            IntPtr intPtr = Marshal.AllocHGlobal(m_recipients.Count * size);

            int ptr = (int)intPtr;
            foreach (MapiRecipDesc mapiDesc in m_recipients)
            {
                Marshal.StructureToPtr(mapiDesc, (IntPtr)ptr, false);
                ptr += size;
            }

            recipCount = m_recipients.Count;
            return intPtr;
        }

        IntPtr GetAttachments(out int fileCount)
        {
            fileCount = 0;
            if (Attachments == null)
                return IntPtr.Zero;

            if ((Attachments.Count <= 0) || (Attachments.Count > maxAttachments))
                return IntPtr.Zero;

            int size = Marshal.SizeOf(typeof(MapiFileDesc));
            IntPtr intPtr = Marshal.AllocHGlobal(Attachments.Count * size);

            MapiFileDesc mapiFileDesc = new MapiFileDesc();
            mapiFileDesc.position = -1;
            int ptr = (int)intPtr;
            
            foreach (string strAttachment in Attachments)
            {
                mapiFileDesc.name = Path.GetFileName(strAttachment);
                mapiFileDesc.path = strAttachment;
                Marshal.StructureToPtr(mapiFileDesc, (IntPtr)ptr, false);
                ptr += size;
            }

            fileCount = Attachments.Count;
            return intPtr;
        }

        void Cleanup(ref MapiMessage msg)
        {
            int size = Marshal.SizeOf(typeof(MapiRecipDesc));
            int ptr = 0;

            if (msg.recips != IntPtr.Zero)
            {
                ptr = (int)msg.recips;
                for (int i = 0; i < msg.recipCount; i++)
                {
                    Marshal.DestroyStructure((IntPtr)ptr, typeof(MapiRecipDesc));
                    ptr += size;
                }
                Marshal.FreeHGlobal(msg.recips);
            }

            if (msg.files != IntPtr.Zero)
            {
                size = Marshal.SizeOf(typeof(MapiFileDesc));

                ptr = (int)msg.files;
                for (int i = 0; i < msg.fileCount; i++)
                {
                    Marshal.DestroyStructure((IntPtr)ptr, typeof(MapiFileDesc));
                    ptr += size;
                }
                Marshal.FreeHGlobal(msg.files);
            }
            
            m_lastError = 0;
        }
        
        public string GetLastError()
		{
		    if (m_lastError <= 26)
			    return errors[ m_lastError ];
		    return "MAPI error [" + m_lastError.ToString() + "]";
		}

	    readonly string[] errors = new string[] {
		"OK [0]", "User abort [1]", "General MAPI failure [2]", "MAPI login failure [3]",
		"Disk full [4]", "Insufficient memory [5]", "Access denied [6]", "-unknown- [7]",
		"Too many sessions [8]", "Too many files were specified [9]", "Too many recipients were specified [10]", "A specified attachment was not found [11]",
		"Attachment open failure [12]", "Attachment write failure [13]", "Unknown recipient [14]", "Bad recipient type [15]",
		"No messages [16]", "Invalid message [17]", "Text too large [18]", "Invalid session [19]",
		"Type not supported [20]", "A recipient was specified ambiguously [21]", "Message in use [22]", "Network failure [23]",
		"Invalid edit fields [24]", "Invalid recipients [25]", "Not supported [26]" 
		};


        List<MapiRecipDesc> m_recipients	= new List<MapiRecipDesc>();
        int m_lastError = 0;

        const int MAPI_LOGON_UI = 0x00000001;
        const int MAPI_DIALOG = 0x00000008;
        const int maxAttachments = 20;

        enum HowTo{MAPI_ORIG=0, MAPI_TO, MAPI_CC, MAPI_BCC};
        
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
        private class MapiMessage
        {
            public int reserved;
            public string subject;
            public string noteText;
            public string messageType;
            public string dateReceived;
            public string conversationID;
            public int flags;
            public IntPtr originator;
            public int recipCount;
            public IntPtr recips;
            public int fileCount;
            public IntPtr files;
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
        private class MapiFileDesc
        {
            public int reserved;
            public int flags;
            public int position;
            public string path;
            public string name;
            public IntPtr type;
        }

        [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Ansi)]
        private class MapiRecipDesc
    	{
    	    public int		reserved;
    	    public int		recipClass;
    	    public string	name;
    	    public string	address;
    	    public int		eIDSize;
    	    public IntPtr	entryID;
    	}

    }

}

"@
