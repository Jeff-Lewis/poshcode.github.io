<#
.SYNOPSIS
An attempt to send text messages to phones. 

.DESCRIPTION
Have you ever wrote a deamon script that notifies you when a server is down or something else. Wouldn't it be nice to get a TEXT (SMS) message.

.EXAMPLE 
Send-TextMessage -Port 587 -SmtpServer 'smtp.gmail.com' -UseSsl -Body 'Hello World' -From 'evilperson@gmail.com' -Subject '>=)' -Number '7238675309' -ServiceProvider Verizon -Credential (Get-Credential)

This will send a text message to 7238675309 from evilperson@gmail.com

.NOTES
This is pretty lame if you already know the person's text email address gateway thing.
#>


[CmdletBinding(HelpUri='http://go.microsoft.com/fwlink/?LinkID=135256')]
param(

    #Specifies the body (content) of the text message.
    [Parameter(Mandatory=$true)]
    [Alias('Message')]
    [ValidateNotNullOrEmpty()]
    [ValidateLength(1,159)]
    [string]$Body,

    #Specifies the address from which the message is sent.
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$From,

    #Specifies the name of the SMTP server that sends the text message.
    [Parameter()]
    [Alias('ComputerName')]
    [ValidateNotNullOrEmpty()]
    [string]$SmtpServer,

    #Specifies the subject of the text message. This parameter is required.
    [Parameter(Mandatory=$true)]
    [Alias('sub')]
    [ValidateNotNullOrEmpty()]
    [string]$Subject,

    #Specifies the phone number to which the text message is sent.
    [Parameter(Mandatory=$true)]
    [Alias('To','PhoneNumber')]
    [ValidateNotNullOrEmpty()]
    [string]$Number,

    #Specifies a user account that has permission to perform this action. The default is the current user.
    [ValidateNotNullOrEmpty()]
    [pscredential]$Credential,

    #Uses the Secure Sockets Layer (SSL) protocol to establish a connection to the remote computer to send mail. By default, SSL is not used.
    [switch]$UseSsl,

    #Specifies an alternate port on the SMTP server.
    [ValidateRange(0, 2147483647)]
    [int]$Port,

    #Carriers providing Short Message Service (SMS) transit via SMS gateways.
    [Parameter(Mandatory=$true)]
    [ValidateSet('USCellular','Verizon','ATT','Sprint','Virgin','T-Mobile','Cricket')]
    [string]$ServiceProvider
)

switch ($ServiceProvider) {
    'USCellular' {$Recipient="$Number@email.uscc.net"}
    'Verizon' {$Recipient="$Number@vtext.com"}
    'ATT' {$Recipient="$Number@vmobl.com"}
    'Sprint' {$Recipient="$Number@messaging.sprintpcs.com"}
    'Virgin' {$Recipient="$Number@vmobl.com"}
    'T-Mobile' {$Recipient="$Number@tmomail.net"}
    'Cricket' {$Recipient="$Number@sms.mycricket.com"}
    default {throw 'How did this happen?'}
}

$Information = @{Body=$Body;From=$From;SmtpServer=$SmtpServer;Subject=$Subject;To=$Recipient;Credential=$Credential;UseSsl=$UseSsl;Port=$Port}

try{
    Send-MailMessage @Information
}
catch{
    throw "Awe, it didn't work."
}
