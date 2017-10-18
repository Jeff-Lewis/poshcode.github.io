Function Get-MACFromIP {
param ($IPAddress)

$sign = @"
using System;
using System.Collections.Generic;
using System.Text;
using System.Net;
using System.Net.NetworkInformation;
using System.Runtime.InteropServices;

public static class NetUtils
{
    [System.Runtime.InteropServices.DllImport("iphlpapi.dll", ExactSpelling = true)]
    static extern int SendARP(int DestIP, int SrcIP, byte[] pMacAddr, ref int PhyAddrLen);

    public static string GetMacAddress(String addr)
    {
        try
                {                   
                    IPAddress IPaddr = IPAddress.Parse(addr);
                   
                    byte[] mac = new byte[6];
                    
                    int L = 6;
                    
                    SendARP(BitConverter.ToInt32(IPaddr.GetAddressBytes(), 0), 0, mac, ref L);
                    
                    String macAddr = BitConverter.ToString(mac, 0, L);
                    
                    return (macAddr.Replace('-',':'));
                }

                catch (Exception ex)
                {
                    return (ex.Message);              
                }
    }
}
"@


$type = Add-Type -TypeDefinition $sign -Language CSharp -PassThru


$type::GetMacAddress($IPAddress)

}
