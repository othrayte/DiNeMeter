package dinemeter.daemon;

import cpp.FileSystem;
import cpp.Lib;
import cpp.Sys;
import dinemeter.client.BackendRequest;
import dinemeter.Config;
import dinemeter.Fatal;
import haxe.Http;
import cpp.io.File;
import cpp.io.FileOutput;
import haxe.io.Eof;
import haxe.Unserializer;

/**
 * ...
 * @author Adrian Cowan (Othrayte)
 */

class DaemonUpdate {
	static var valid:Bool = false;
    static var setupVersion:Float = 0.00166;
	
	public static function main() {
		//trace(StringTools.replace(Serializer.run("http://localhost/DiNeMeter/"), ":", "."));
		var findName = ~/[\\\/]([^\\\/]*$)/;
		var findDetails = ~/[\[]([^]]*)[\]]/;
		//"[y47.http%3A%2F%2Flocalhost%2FDiNeMeter%2F%2Cdefault]"
        
        var exe = cpp.Sys.executablePath();
        cpp.Sys.setCwd(exe.substr(0, exe.lastIndexOf("\\") + 1));
        
        new Log("./setup-log.txt", "./setup-error-log.txt", false);
        
		try {
			var installPath:String;
            var username:String = null;
            var password:String = null;
            var url:String = "";
            var update:Bool;
            
            if (FileSystem.exists("daemon-config.txt")) {
                installPath = cpp.Sys.getCwd();
            } else {
                installPath = cpp.Sys.getEnv("ProgramFiles") + "\\DiNeMeter\\";
            }
            
                trace("AAF - "+cpp.Sys.executablePath());
            if (FileSystem.exists(installPath + "daemon-config.txt")) {
                var daemonConfig:Config = new Config(installPath + "daemon-config.txt");
                username = daemonConfig.get("username");
                password = daemonConfig.get("password");
                url = daemonConfig.get("master-url");
                BackendRequest.url = url;
                BackendRequest.usePassword(password, username);
                new Log("./setup-log.txt", "./setup-error-log.txt", true);
                update = true;
            } else {
                findName.match(cpp.Sys.executablePath());
                var exename:String = findName.matched(1);
                if (exename != null) {
                    findDetails.match(exename);
                    var details:String = Unserializer.run(StringTools.replace(findDetails.matched(1), ";", ":"));
                    if (details != null) {
                        url = details.split(",")[0];
                        Log.msg("Backend url: "+url);
                        username = details.split(",")[1];
                        Log.msg("Username: "+username);
                        Lib.println("Username: " + username);
                        var valid = false;
                        do {
                            Lib.print("Password: ");
                            var input = File.stdin();
                            password = input.readLine();
                            BackendRequest.url = url;
                            BackendRequest.usePassword(password, username);
                            var waiting = true;
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
                        new Log("./setup-log.txt", "./setup-error-log.txt", true);
                    }
                }
                update = false;
            }
            if (url == "") throw new Fatal(OTHER("Setup: Missing url"));
            if (username == null) throw new Fatal(OTHER("Setup: Missing username"));
            if (password == null) throw new Fatal(OTHER("Setup: Missing password"));
            Lib.println("Downloading files from: " + url);
            Lib.println("Installing files to: " + installPath);
            var daemonConfig:Config = new Config();
            var version:Float;            
            if (update) {
                Log.msg("Going to update program");
                // Update current instalation
                daemonConfig = new Config(installPath+"daemon-config.txt");
                version = setupFrom(url, installPath, daemonConfig.get("version"), daemonConfig.get("upd-version"));
            } else {
                Log.msg("Going to install program");
                // Setup from scratch
                if (!cpp.FileSystem.exists(installPath.substr(0, installPath.length - 1)))
                    cpp.FileSystem.createDirectory(installPath);
                version = setupFrom(url, installPath, 0, setupVersion);
            }
            if (FileSystem.exists("daemon-common-config.txt")) {
                var commonConf = new Config("daemon-common-config.txt");
                daemonConfig.set("subnet", commonConf.get("subnet"));
                daemonConfig.set("subnet-mask", commonConf.get("subnet-mask"));
            } else {
                daemonConfig.set("subnet", "192.168.1.0");
                daemonConfig.set("subnet-mask", "255.255.255.0");
            }
            daemonConfig.set("master-url", url);
            daemonConfig.set("username", username);
            daemonConfig.set("password", password);
            daemonConfig.set("version", version);
            daemonConfig.set("upd-version", setupVersion);
            daemonConfig.set("log", "./log.txt");
            daemonConfig.set("error-log", "./errors.txt");
            daemonConfig.set("report-errors", true);
            daemonConfig.writeFile(installPath+"daemon-config.txt");
            Log.msg("Instalation Complete");
            Lib.println("Instalation Complete");
            return;
        } catch (f:Fatal) {
            Log.err(f, "Setup error.\nThis error was caught at the last possible stage, this should have been caught earlier");
            Sys.exit( -1);
        } catch (e:Dynamic) {
            Log.err(new Fatal(OTHER(e)), "Setup error.\nThis error was caught at the last possible stage, this should have been caught earlier");
            Sys.exit( -1);
        }
	}
	
	private static function setupFrom(url:String, installPath:String, ?currentVersion:Float = 0., ?currentSetupVersion:Float = 0.) {
        Log.msg("Running setup script");
        Log.msg("Master server: " + url);
        Log.msg("Current version: " + currentVersion);
        Log.msg("Current setup version: " + currentSetupVersion);
		var version = 0.;
		try {
            var raw:String;
			try {
                raw = Http.requestUrl(url + "daemon.meta");
            } catch (e:Eof) {
                throw new Fatal(OTHER("Setup script error, couldn't get script (EOF)"));
            }
			raw = StringTools.replace(raw, "\r\n", "\n");
			var lines:Array<String> = raw.split("\n");
			for (line in lines) {
                line = StringTools.replace(line, "::", "`;`");
				var data = line.split(":");
				for (i in 0 ... data.length) {
					data[i] = StringTools.replace(data[i], "%%INSTALL_PATH%%", installPath);
                    data[i] = StringTools.replace(data[i], "`;`", ":");
				}
                if (data[1] == "@upd") {
                    //Install file to install dir
                    if (currentVersion == 0) {
                        //Install setup file to install dir
                        Log.msg("Installing setup file: "+data[2]);
                        Lib.println("Installing setup file: "+data[2]);
                        var req = new Http(url+data[2]);
                        req.onData = function(res) {
                            var b:haxe.io.Bytes = haxe.io.Bytes.ofString(res);
                            var fOut:FileOutput = File.write(installPath+data[2], true);
                            fOut.writeBytes(b, 0, res.length);
                            fOut.close();
                        };
                        req.onError = function(err) { trace("e: "+err); };
                        req.request(false);
                    }
                    if (Std.parseFloat(data[0]) > currentSetupVersion) {
                        throw new Fatal(OTHER("Cant update, updater is out of date"));
                    }
                }
                // If newer do
                Log.msg(" Next command: " + data);
                if (Std.parseFloat(data.shift()) > currentVersion) {
                    Log.msg(" Exec command: " + data);
                    switch (data[0]) {
                        case "@v"://Set version number
                            version = Std.parseFloat(data[1]);
                            Log.msg("New version number: " + version);
                        case "@upd"://ignore
                        case "@i"://Install file to install dir
                            Log.msg("Installing file: "+data[1]);
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
                            Log.msg("Downloading file: "+data[1]);
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
                            Log.msg("Executing file: " + data[1]);
                            Lib.println("Executing file: " + data[1]);
                            cpp.Sys.command(data[1]);
                            Log.msg("Deleting file: " + data[1]);
                            Lib.println("Deleting file: " + data[1]);
                            cpp.FileSystem.deleteFile("./" + data[1]);
                        case "@t"://Download file to current (temp) directory
                            Log.msg("Downloading temporery file: "+data[1]);
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
                            Log.msg("Adding startup shortcut for: " + data[1]);
                            Lib.println("Adding startup shortcut for: " + data[1]);
                            if (!cpp.FileSystem.exists(cpp.Sys.getEnv("ProgramFiles")+"\\Microsoft\\Windows\\Start Menu\\Programs\\Startup\\DiNeMeter Daemon.lnk")) {
                                //Create shortcut
                                cpp.Sys.command("Shortcut.exe /f:\"%ALLUSERSPROFILE%\\Microsoft\\Windows\\Start Menu\\Programs\\Startup\\DiNeMeter Daemon.lnk\" /a:c /t:\"" + installPath + data[1] + "\" /p:\"" + data[2] + "\" /w:\"" + installPath);
                            } else {
                                //Edit shorcut
                                cpp.Sys.command("Shortcut.exe /f:\"%ALLUSERSPROFILE%\\Microsoft\\Windows\\Start Menu\\Programs\\Startup\\DiNeMeter Daemon.lnk\" /a:e /t:\"" + installPath + data[1] + "\" /p:\"" + data[2] + "\" /w:\"" + installPath);
                            }
                        case "@e"://Execute hidden
                            Log.msg("Executing (hidden) file: " + data[1]);
                            Lib.println("Executing (hidden) file: " + data[1]);
                            var wd = cpp.Sys.getCwd();
                            Log.msg("cwd: " + cpp.Sys.getCwd());
                            Lib.println("cwd: " + cpp.Sys.getCwd());
                            cpp.Sys.setCwd(installPath);
                            Log.msg("cwd: " + cpp.Sys.getCwd());
                            Lib.println("cwd: " + cpp.Sys.getCwd());
                            cpp.Sys.command("\"" + installPath + "runhide.exe\" " + data[1]);// Not Working
                            cpp.Sys.setCwd(wd);
                            Log.msg("cwd: " + cpp.Sys.getCwd());
                            Lib.println("cwd: " + cpp.Sys.getCwd());
                        case "@d"://Delete from install dir
                            Log.msg("Deleting file: " + data[1]);
                            Lib.println("Deleting file: " + data[1]);
                            cpp.FileSystem.deleteFile(installPath + data[1]);	
                        case "@dt"://Delete from current dir
                            Log.msg("Deleting temporery file: " + data[1]);
                            Lib.println("Deleting temporery file: " + data[1]);
                            cpp.FileSystem.deleteFile("./" + data[1]);
                        case "@cmd"://Run a cmd on the cmd line (from install dir)
                            Log.msg("Executing command: " + data[1] + ">" + data.slice(2).join(" "));
                            Lib.println("Executing command: " + data[1] + ">" + data.slice(2).join(" "));
                            var wd = cpp.Sys.getCwd();
                            cpp.Sys.setCwd(installPath);
                            cpp.Sys.command(data[1], data.slice(2));
                            cpp.Sys.setCwd(wd);
                        case "@cmd!"://Run a cmd on the cmd line (from a batch file)
                            Log.msg("Executing command via bat file: " + data[1] + ">" + data.slice(2).join(" "));
                            Lib.println("Executing command via bat file: " + data[1] + ">" + data.slice(2).join(" "));
                            var bat = File.write("temp.bat", false);
                            bat.writeString(data.slice(1).join(" "));
                            bat.close();
                            trace(data.slice(1).join(" "));
                            cpp.Sys.command("temp.bat");
                            FileSystem.deleteFile("temp.bat");
                    }
                }
			}
		} catch (f:Fatal) {
            throw f;
		} catch (e:Dynamic) {
			throw new Fatal(OTHER("Setup script error " + Std.string(e)));
		}
		return version;
	}
	
}