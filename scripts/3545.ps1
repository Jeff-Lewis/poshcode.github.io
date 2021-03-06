from System import Array, Char, Console
from System.Collections import ArrayList
from Microsoft.Win32 import Registry

def DecodeProductKey(digitalProductID):
   map = ("BCDFGHJKMPQRTVWXY2346789").ToCharArray()
   key = Array.CreateInstance(Char, 29)
   raw = ArrayList()

   i = 52
   while i < 67:
      raw.Add(digitalProductID[i])
      i += 1

   i = 28
   while i >= 0:
      if (i + 1) % 6 == 0:
         key[i] = '-'
      else:
         k = 0
         j = 14
         while j >= 0:
            k = (k * 256) ^ raw[j]
            raw[j] = (k / 24)
            k %= 24
            key[i] = map[k]
            j -= 1
      i -= 1

   return key

reg = Registry.LocalMachine.OpenSubKey("SOFTWARE\Microsoft\Windows NT\CurrentVersion")
val = reg.GetValue("DigitalProductId")
Console.WriteLine(DecodeProductKey(val))
