package dinemeter.daemon;

import cpp.FileSystem;
import cpp.Lib;
import dinemeter.client.BackendRequest;
import dinemeter.Config;
import haxe.Http;
import cpp.io.File;
import cpp.io.FileOutput;
import haxe.Unserializer;

/**
 * ...
 * @author Adrian Cowan (Othrayte)
 */

class DaemonSetup {
	static var waiting:Bool = false;
	static var valid:Bool = false;
	static var installPath:String = "./";
	
	public static function main() {
		//trace(StringTools.replace(Serializer.run("http://localhost/DiNeMeter/"), ":", "."));
		var findName = ~/[\\\/]([^\\\/]*$)/;
		var findDetails = ~/[\[]([^]]*)[\]]/;
		//"[y47.http%3A%2F%2Flocalhost%2FDiNeMeter%2F%2Cdefault]"
		try {
			findName.match(cpp.Sys.executablePath());
			var exename:String = findName.matched(1);
			if (exename != null) {
				findDetails.match(exename);
				var details:String = Unserializer.run(StringTools.replace(findDetails.matched(1), ".", ":"));
				if (details != null) {
					var url:String = details.split(",")[0];
					var username:String = details.split(",")[1];
					Lib.println("Username: " + username);
					var password;
					do {
						Lib.print("Password: ");
						var input = File.stdin();
						password = input.readLine();
						BackendRequest.url = url;
						BackendRequest.usePassword(password, username);
						waiting = true;
						BackendRequest.checkCreds(function(correct) {
							if (correct) {
								Lib.println("Correct.");
							} else {
								Lib.println("Incorrect");
							}
							waiting = false;
							valid = correct;
						});
						while (waiting) {cpp.Sys.sleep(0.1);} // responce should be syncronous but just in case
					} while (!valid);
					installPath = cpp.Sys.getEnv("ProgramFiles") + "\\DiNeMeter\\";
					Lib.println("Downloading files from: " + url);
					Lib.println("Installing files to: " + installPath);
					if (!cpp.FileSystem.exists(installPath.substr(0, installPath.length-1))) cpp.FileSystem.createDirectory(installPath);
					var version = setupFrom(url);
					var daemonConfig:Config = new Config();
					daemonConfig.set("password", password);
					daemonConfig.set("master-url", url);
					daemonConfig.set("username", username);
					daemonConfig.set("version", version);
					daemonConfig.set("log", "./log.txt");
					daemonConfig.set("error-log", "./errors.txt");
					daemonConfig.set("report-errors", true);
					daemonConfig.writeFile(installPath+"daemon-config.txt");
					
					Lib.println("Instalation Complete");
					File.stdin().readLine();
					return;				
				}
			}
		}
		catch (e:Dynamic) {	}
	}
	
	private static function setupFrom(url:String) {
		var version = 0.;
		try {
			var raw = Http.requestUrl(url + "daemon.meta");
			raw = StringTools.replace(raw, "\r\n", "\n");
			var lines:Array<String> = raw.split("\n");
			for (line in lines) {
                line = StringTools.replace(line, "::", "`;`");
				var data = line.split(":");
				for (i in 0 ... data.length) {
					data[i] = StringTools.replace(data[i], "%%INSTALL_PATH%%", installPath);
                    data[i] = StringTools.replace(data[i], "`;`", ":");
				}
				switch (data[0]) {
					case "@v"://Set version number
						version = Std.parseFloat(data[1]);
					case "@i"://Install file to install dir
						Lib.println("Installing file: "+data[1]);
						var req = new Http(url+data[1]);
						req.onData = function(res) {
							var b:haxe.io.Bytes = haxe.io.Bytes.ofString(res);
							var fOut:FileOutput = File.write(installPath+data[1], true);
							fOut.writeBytes(b, 0, res.length);
							fOut.close();
						};
						req.onError = function(err) { trace("e: "+err); };
						req.request(false);
					case "@r"://Exec file in current (temp) directory
						Lib.println("Downloading file: "+data[1]);
						var req = new Http(url+data[1]);
						req.onData = function(res) {
							var b:haxe.io.Bytes = haxe.io.Bytes.ofString(res);
							var fOut:FileOutput = File.write("./"+data[1], true);
							fOut.writeBytes(b, 0, res.length);
							fOut.close();
						};
						req.onError = function(err) { trace("e: "+err); };
						req.request(false);
						Lib.println("Executing file: " + data[1]);
						cpp.Sys.command(data[1]);
						Lib.println("Deleting file: " + data[1]);
						cpp.FileSystem.deleteFile("./" + data[1]);
					case "@t"://Download file to current (temp) directory
						Lib.println("Downloading temporery file: "+data[1]);
						var req = new Http(url+data[1]);
						req.onData = function(res) {
							var b:haxe.io.Bytes = haxe.io.Bytes.ofString(res);
							var fOut:FileOutput = File.write("./"+data[1], true);
							fOut.writeBytes(b, 0, res.length);
							fOut.close();
						};
						req.onError = function(err) { trace("e: "+err); };
						req.request(false);
					case "@s"://Set as start program
						Lib.println("Adding startup shortcut for: " + data[1]);
						if (!cpp.FileSystem.exists(cpp.Sys.getEnv("ProgramFiles")+"\\Microsoft\\Windows\\Start Menu\\Programs\\Startup\\DiNeMeter Daemon.lnk")) {
							//Create shortcut
							cpp.Sys.command("Shortcut.exe /f:\"%ALLUSERSPROFILE%\\Microsoft\\Windows\\Start Menu\\Programs\\Startup\\DiNeMeter Daemon.lnk\" /a:c /t:\"" + installPath + data[1] + "\" /p:\"" + data[2] + "\" /w:\"" + installPath);
						} else {
							//Edit shorcut
							cpp.Sys.command("Shortcut.exe /f:\"%ALLUSERSPROFILE%\\Microsoft\\Windows\\Start Menu\\Programs\\Startup\\DiNeMeter Daemon.lnk\" /a:e /t:\"" + installPath + data[1] + "\" /p:\"" + data[2] + "\" /w:\"" + installPath);
						}
					case "@e"://Execute hidden
						Lib.println("Executing (hidden) file: " + data[1]);
						var wd = cpp.Sys.getCwd();
						Lib.println("cwd: " + cpp.Sys.getCwd());
						cpp.Sys.setCwd(installPath);
						Lib.println("cwd: " + cpp.Sys.getCwd());
						cpp.Sys.command("\"" + installPath + "runhide.exe\" " + data[1]);// Not Working
						cpp.Sys.setCwd(wd);
						Lib.println("cwd: " + cpp.Sys.getCwd());
					case "@d"://Delete from install dir
						Lib.println("Deleting file: " + data[1]);
						cpp.FileSystem.deleteFile(installPath + data[1]);	
					case "@dt"://Delete from current dir
						Lib.println("Deleting temporery file: " + data[1]);
						cpp.FileSystem.deleteFile("./" + data[1]);
					case "@cmd"://Run a cmd on the cmd line (from install dir)
						var wd = cpp.Sys.getCwd();
						cpp.Sys.setCwd(installPath);
						trace(data[1] + ">" + data.slice(2).join(" "));
						cpp.Sys.command(data[1], data.slice(2));
						cpp.Sys.setCwd(wd);
					case "@cmd!"://Run a cmd on the cmd line (from a batch file)
						var bat = File.write("temp.bat", false);
                        bat.writeString(data.slice(1).join(" "));
						bat.close();
                        trace(data.slice(1).join(" "));
						cpp.Sys.command("temp.bat");
                        FileSystem.deleteFile("temp.bat");
				}
			}
		}
		catch (e:Dynamic) {
			trace("error: " + e + "<");
		}
		return version;
	}
	
}