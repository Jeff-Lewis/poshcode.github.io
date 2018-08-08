cls

$ws  =  New-WebServiceProxy -Uri "http://192.168.1.1/sdk/vimService?wsdl" -namespace VIM -class VIM;

$ws.Url = "http://192.168.1.1/sdk/vimService";
$ws.UserAgent = "VMware VI Client/4.0.0";
$ws.CookieContainer = New-Object system.net.CookieContainer;

# set up some default MoRefs (see SDK docs)
# if anyone knows how to work around these auto-gen types, then please let me know

$mor_ret = new-object Microsoft.PowerShell.Commands.NewWebserviceProxy.AutogeneratedTypes.WebServiceProxy192_168_1_1_sdk_vimService_wsdl.ManagedObjectReference;

#now becomes (VIM being the namespace)
$mor_ret = new-object VIM.ManagedObjectReference;

$mor_si = new-object Microsoft.PowerShell.Commands.NewWebserviceProxy.AutogeneratedTypes.WebServiceProxy192_168_1_1_sdk_vimService_wsdl.ManagedObjectReference;
$mor_si.type = "ServiceInstance";
$mor_si.Value = "ServiceInstance";

$mor_sm = new-object Microsoft.PowerShell.Commands.NewWebserviceProxy.AutogeneratedTypes.WebServiceProxy192_168_1_1_sdk_vimService_wsdl.ManagedObjectReference;
$mor_sm.type = "SessionManager";
$mor_sm.Value = "ha-sessionmgr";

$mor_hs = new-object Microsoft.PowerShell.Commands.NewWebserviceProxy.AutogeneratedTypes.WebServiceProxy192_168_1_1_sdk_vimService_wsdl.ManagedObjectReference;
$mor_hs.type = "HostSystem";
$mor_hs.Value = "ha-host";

$us = $ws.Login($mor_sm,"root","root", "en");

write-Host $ws.CurrentTime($mor_si);

#$mor_ret = $ws.RebootHost_Task($mor_hs, $true);

$ws.Logout($mor_sm);
