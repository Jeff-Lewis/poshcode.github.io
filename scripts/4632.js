var rnd = rnd || {
  getRandomNumber : function(min, max) {
    return Math.floor(Math.random() * (max - min + 1)) + min;
  },
  
  setRandomFile : function(dir, len) {
    if (len > 32 || len < 1) WScript.Quit(1);
    
    var arr, ext = [], i, r, std;
    with (new ActiveXObject('WScript.Shell')) {
      std = Exec("cmd /q /k echo off");
      std.StdIn.WriteLine("assoc & exit");
      arr = std.StdOut.ReadAll().split('\n');
      
      for (i = 0; i < arr.length; i++) {
        if (!arr[i].match(/.\d+\=/) && arr[i].match(/=\w+/)) {
          ext.push(arr[i].split('=')[0]);
        }
      }
    }
    
    r = this.getRandomNumber(0, ext.length - 1);
    
    with (new ActiveXObject('Scriptlet.TypeLib')) {
      return dir + GUID.substring(1, 37).replace(/-/g, '').toLowerCase().slice(0, len) + ext[r];
    }
  }
}

//usung examples
with (new ActiveXObject('Scripting.FileSystemObject')) {
  CreateTextFile(rnd.setRandomFile(32));
  CreateTextFile(rnd.setRandomFile('E:\\test\\', 13));
}
