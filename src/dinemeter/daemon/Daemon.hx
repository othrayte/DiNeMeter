#if cpp
package dinemeter.daemon;
import cpp.Lib;
import haxe.Http;
import haxe.io.Eof;
import haxe.remoting.Connection;
import haxe.Serializer;
import haxe.Timer;
import cpp.vm.Mutex;
import cpp.vm.Thread;
import cpp.io.File;
import cpp.io.FileOutput;

import dinemeter.Config;
import dinemeter.Fatal;
import dinemeter.client.BackendRequest;
import dinemeter.TimeUtils;
import dinemeter.DataRecord;
import dinemeter.daemon.DataCache;
import dinemeter.daemon.Filter;

/**
 *  This file is part of DiNeMeterDaemon.
 *
 *  DiNeMeterDaemon is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  any later version.
 *
 *  DiNeMeterDaemon is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with DiNeMeterDaemon.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * @author Adrian Cowan (Othrayte)
 */

class Daemon {
	static var vals:IntHash<{down:Int, up:Int}> = new IntHash();
	static var valsMutex:Mutex = new Mutex();
	static var totals: { down:Int , up:Int , uDown:Int , uUp:Int } = { down: 0, up: 0, uDown:0 , uUp:0 };
	static var totalsMutex:Mutex = new Mutex();
	static var start:Int;
	static var end:Int;
	
	static var t:Int;
	static var unmetered:Filter;
	static var realtimeTimer:Timer;
	static var daemonConf:Config;

	public static function main() {
		//trace(StringTools.replace(Serializer.run("http://localhost/DiNeMeter/,default"), ":", "."));
        var exe = cpp.Sys.executablePath();
        cpp.Sys.setCwd(exe.substr(0,exe.lastIndexOf("\\")+1));
        
		daemonConf = new Config("./daemon-config.txt");
		
        Log.setup(daemonConf);
        
        try {
            BackendRequest.url = daemonConf.get("master-url");
            DataCache.setFile("./out.txt");
            
            Log.msg("DiNeMeter Daemon started in " + cpp.Sys.getCwd());
            
            var username:String = daemonConf.get("username");
            if (username == null) throw new Fatal(CLIENT_ERROR(NO_USERNAME));
            var password:String = daemonConf.get("password");
            if (password == null) throw new Fatal(CLIENT_ERROR(NO_PASSWORD));
            
            Log.msg("Username and password found");
            
            BackendRequest.usePassword(password, username);
            end = Std.int(Date.now().getTime() / 1000);
            
            Log.msg("Creating realtime logging thread");
            Thread.create(realtimeTiming);
            Log.msg("Creating output logging thread");
            Thread.create(outputTiming);
            Log.msg("Creating autoupdate thread");
            Thread.create(updateTiming);
            
            var a:Array<String> = listDevices();
            if (a.length == 0) throw new Fatal(CLIENT_ERROR(NO_DEVICES_FOUND));
            
            Log.msg("Reading unmetered ip list");
            unmetered = readIpList(File.getContent("unmetered.txt"));
            
            var devices:Array<String> = new Array();
            for (i in 0 ... Math.floor(a.length / 2)) {
                Log.msg("Using device '" + a[i*2+1] + "'");
                devices.push(a[i*2]);
            }
            while (true) {
                var responce = run(devices, daemonConf.get("subnet"), daemonConf.get("subnet-mask"), handler);
                Log.msg("Reached end, error");
                cpp.Sys.sleep(3);
            }
        } catch (f:Fatal) {
            Log.err(f, "This error was caught at the last possible stage, this should have been caught earlier");
        } catch (e:Dynamic) {
            Log.err(new Fatal(OTHER(e)), "This error was caught at the last possible stage, this should have been caught earlier");
        }
	}
	
	public static function handler(down:Int, up:Int, add:Int) {
		//Lib.println(add);
		valsMutex.acquire();
		if (!vals.exists(add)) {
			vals.set(add, { down: down, up: up } );
		} else {
			vals.get(add).down += down;
			vals.get(add).up += up;
			//up += vals.get(add).up;
			//vals.set(add, { down: down, up: up } );
		}
		valsMutex.release();
	}
	
	public static function realtimeTiming():Void {
		var thread:Thread = Thread.create(realtime);
		while (true) { 
			cpp.Sys.sleep(0.500);
			thread.sendMessage(null);
		}
	}
	
	public static function realtime():Void {
		while (true) {
			Thread.readMessage(true);
			valsMutex.acquire();
			var vals = Daemon.vals;
			Daemon.vals = new IntHash();
			valsMutex.release();
			var v: { down:Int , up:Int , uDown:Int , uUp:Int } = {down: 0,up: 0,uDown:0 ,uUp:0};
			for (key in vals.keys()) {
				Lib.println("Free: " + match(unmetered, key) + "\t" + printIp(key) + "\t" + vals.get(key).down + "\t" + vals.get(key).up);
				if (match(unmetered, key)) {
					v.uDown = vals.get(key).down;
					v.uUp = vals.get(key).up;
				} else {
					v.down = vals.get(key).down;
					v.up = vals.get(key).up;
				}
			}
			totalsMutex.acquire();
			totals.down += v.down;
			totals.up += v.up;
			totals.uDown += v.uDown;
			totals.uUp += v.uUp;
			totalsMutex.release();
			var out:String = Timer.stamp() + ":" + v.down / 500 + "," + v.uDown / 500 + "," + v.up / 500;// + "," + v.uUp;
			try {
				var realtimeFile:FileOutput = File.write("realtime.txt", false);
				if (realtimeFile == null) {
					Log.msg("[Realtime] realtime.txt could not be opened");
				} else {
					realtimeFile.writeString(out);
					realtimeFile.close();
				}
			} catch (e:Dynamic) {
				Log.msg("[Realtime] error caught when trying to use realtime.txt");
			}
		}
	}
	
	public static function outputTiming():Void {
		var thread:Thread = Thread.create(output);
		while (true) { 
			cpp.Sys.sleep(30);
			thread.sendMessage(null);
		}
	}
	
	public static function output():Void {
		while (true) {
			Thread.readMessage(true);
			totalsMutex.acquire();
			var v: { down:Int , up:Int , uDown:Int , uUp:Int } = totals;
			totals = { down: 0, up: 0, uDown:0 , uUp:0 };
			start = end;
			end = Std.int(Date.now().getTime() / 1000);
			totalsMutex.release();
			
			var dR:DataRecord = new DataRecord();
			dR.down = v.down;
			dR.up = v.up;
			dR.uDown = v.uDown;
			dR.uUp = v.uUp;
			dR.start = start;
			dR.end = end;
			
			
			var usernames:List<String> = new List();
			usernames.add(daemonConf.get("username"));
			var data:List<DataRecord> = new List();
			data.add(dR);
			
			var info:CacheItem = new CacheItem(data, usernames, 3);
			Log.msg("Sending data to server");
			var req = BackendRequest.putData(usernames, data, 3, callback(outputResponce, info));
		}
	}
	
	public static function outputResponce(info:CacheItem, responce:Array<Dynamic>) {
		var failed:Bool = false;
		for (item in responce) {
			if (Std.is(item, Fatal)) {
				Log.msg("[Output] bad responce "+item.message);
				failed = true;
			} else if (Std.is(item, Eof)) {
				Log.msg("[Output] eof error??");
				failed = true;
			}
		}
		if (failed) {
			DataCache.append(info);			
		}
	}
	
	public static function printIp(i:Int):String {
		return (i & 0xFF) + "." + (i >> 8 & 0xFF) + "." + (i >> 16 & 0xFF) + "." + (i >> 24 & 0xFF);
	}
	
	public static function splitIp(i:Int):{a:Int, b:Int, c:Int, d:Int} {
		return {a:(i & 0xFF), b:(i >> 8 & 0xFF), c:(i >> 16 & 0xFF), d:(i >> 24 & 0xFF)};
	}
	
	public static function match(filter:Filter, ip:Int):Bool {
		var i:Array<Int> = new Array();
		var part: { a:Int, b:Int, c:Int, d:Int } = splitIp(ip);
		i[0] = part.a;
		i[1] = part.b;
		i[2] = part.c;
		i[3] = part.d;
		var f:Array<Filter> = new Array();
		if (filter==null) {
			Log.msg("[Filter] bad filter");
			return false;
		}
		f[0] = filter;
		var level:Int = 0;
		while (level!=-1) {
			if (f[level].min<=i[level]&&f[level].max>=i[level]) {
				if (level == 3) return true;
				f[level+1] = f[level].child;
				f[level] = f[level].next;
				level++;
			} else {
				f[level] = f[level].next;
			}
			while (f[level] == null && level > -1) {
				level--;
			}
		}
		return false;
	}
	
	public static function readIpList(raw:String):Filter {
		var i1:Int=0, i2:Int=0, i3:Int=0, i4:Int=0, i5:Int=0;
		var c1:Int=0, c2:Int=0, c3:Int=0, c4:Int=0;
		var f1:Filter = new Filter(), f2:Filter = new Filter(), f3:Filter = new Filter(), f4:Filter = new Filter();
		var of1:Filter = new Filter(), of2:Filter = new Filter(), of3:Filter = new Filter(), of4:Filter = new Filter();
		var ppch:Array<String> = new Array();
		var i:Int = 0;
		var head:Filter = new Filter();
		
		ppch = raw.split("\n");
		
		var r = ~/([0-9][0-9]?[0-9]?)\.([0-9][0-9]?[0-9]?)\.([0-9][0-9]?[0-9]?)\.([0-9][0-9]?[0-9]?)(\/([0-9][0-9]?))?/;
		for (line in ppch) {
			if (!r.match(line)) {
				continue;
			}
			
			try {
				i1 = Std.parseInt(r.matched(1));
				i2 = Std.parseInt(r.matched(2));
				i3 = Std.parseInt(r.matched(3));
				i4 = Std.parseInt(r.matched(4));
				i5 = Std.parseInt(r.matched(6));
				if (i5 == 0) i5 = 32;
			} catch (e:Dynamic) {
				i5 = 32;
			}
			
			f4 = new Filter();
			f4.min = i4;
			f4.max = i4+Math.floor(Math.pow(2,32-i5))-1;
			if (i++ == 0) {
				f1 = new Filter();
				head = f1;
				f1.min = i1;
				f1.max = i1;
				f2 = new Filter();
				f2.min = i2;
				f2.max = i2;
				f3 = new Filter();
				f3.min = i3;
				f3.max = i3;
				f1.child = f2;
				f2.child = f3;
				f3.child = f4;
			} else {
				if (i1==c1) {
					if (i2==c2) {
						if (i3==c3) {
							of4.next = f4;
							f4.child = null;
						} else {
							f3 = new Filter();
							f3.min = i3;
							f3.max = i3;
							of3.next = f3;
							of4.next = null;
							f3.child = f4;
						}
					} else {
						f2 = new Filter();
						f2.min = i2;
						f2.max = i2;
						f3 = new Filter();
						f3.min = i3;
						f3.max = i3;
						of2.next = f2;
						of3.next = null;
						of4.next = null;
						f2.child = f3;
						f3.child = f4;
					}
				} else {
					f1 = new Filter();
					f1.min = i1;
					f1.max = i1;
					f2 = new Filter();
					f2.min = i2;
					f2.max = i2;
					f3 = new Filter();
					f3.min = i3;
					f3.max = i3;
					of1.next = f1;
					of2.next = null;
					of3.next = null;
					of4.next = null;
					f1.child = f2;
					f2.child = f3;
					f3.child = f4;
				}
			}
			c1 = i1;
			c2 = i2;
			c3 = i3;
			c4 = i4;
			of1 = f1;
			of2 = f2;
			of3 = f3;
			of4 = f4;
		}
		of1.next = null;
		of2.next = null;
		of3.next = null;
		of4.next = null;
		return head;
	}
	
    
	
	public static function updateTiming():Void {
		var thread:Thread = Thread.create(update);
        cpp.Sys.sleep(10);
        thread.sendMessage(null);
		while (true) {
            cpp.Sys.sleep(30); // hourly (temp changed)
			thread.sendMessage(null);
		}
	}
    
    private static function update() {
		while (true) {
			Thread.readMessage(true);
            // Make sure updater is up to date
            var updV:Float = updateSetupFrom(daemonConf.get("master-url"), cpp.Sys.getCwd(), daemonConf.get("upd-version"));
            daemonConf.set("upd-version", updV);
            daemonConf.writeFile("./daemon-config.txt");
            // check if we actually need to update
            Log.msg("Looking for update");
            var v = checkUpdate();
            if (v > 0) {
                // Create batch file to do update
                Log.msg("New update avaliable (" + v + "), prepareing to update");
                var updateBat = File.write("updateNow.bat", false);
                updateBat.writeString("start DaemonUpdate.exe");
                updateBat.close();
                // Run batch file (initiate update)
                Log.msg("Running update");
                cpp.Sys.command("start updateNow.bat");// Not Working
                Log.msg("Update done");
            }
        }
    }
    
    private static function checkUpdate() {
		try {
			var raw = Http.requestUrl(daemonConf.get("master-url") + "daemon.meta");
			raw = StringTools.replace(raw, "\r\n", "\n");
			var lines:Array<String> = raw.split("\n");
            for (line in lines) {
                line = StringTools.replace(line, "::", "`;`");
				var data = line.split(":");
                if (data[1] == "@v") {
                    var v = Std.parseFloat(data[2]);
                    if (v > daemonConf.get("version"))
                        return v;
                }
            }
        }
		catch (e:Dynamic) {
			throw new Fatal(OTHER("Update check error : " + Std.string(e)));
		}
        return -1;
    }
    
    private static function updateSetupFrom(url:String, installPath:String, ?currentSetupVersion:Float=0.) {
		var version = 0.;
		try {
            Log.msg("Checking for update to updater");
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
                if (data[1] == "@upd") {
                    //Install file to install dir
                    version = Std.parseFloat(data[0]);
                    if (version > currentSetupVersion) {
                        Log.msg("Updating updator to version "+version);
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
                        return version; // Return setup version
                    }
                }
			}
		}
		catch (e:Dynamic) {
			throw new Fatal(OTHER("Update setup script error " + Std.string(e)));
		}
		return version;
	}
    
	private static var run = Lib.load("pcapInterface","run",4);
	private static var listDevices = Lib.load("pcapInterface","listDevices",0);
}
#end

/*

cd E:\Data\Programming\Git\WebMonitorMaster\bin
E:
C:\cygwin\bin\gdb Daemon-debug.exe
b exit
r

*/

/*

cd E:\Data\Programming\Git\WebMonitorMaster\bin
E:
Daemon-debug.exe

*/
