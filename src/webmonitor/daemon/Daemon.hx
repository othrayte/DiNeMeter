#if cpp
package webmonitor.daemon;
import cpp.Lib;
import haxe.remoting.Connection;
import haxe.Timer;
import cpp.vm.Mutex;
import cpp.vm.Thread;
import cpp.io.File;
import cpp.io.FileOutput;

import webmonitor.client.BackendRequest;
import webmonitor.TimeUtils;
import webmonitor.DataRecord;

/**
 *  This file is part of WebMonitorDaemon.
 *
 *  WebMonitorDaemon is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  any later version.
 *
 *  WebMonitorDaemon is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with WebMonitorDaemon.  If not, see <http://www.gnu.org/licenses/>.
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

	public static function main() {
		BackendRequest.url = "http://localhost/WebMonitorMaster/";
		BackendRequest.usePassword("default", "default");
		end = Std.int(Date.now().getTime() / 1000);
		
		Thread.create(realtimeTiming);
		Thread.create(outputTiming);
		
		var a:Array<String> = listDevices();
		if (a.length == 0) throw "no device avaliable";
		Lib.println("Using device '" + a[1] + "'");
		
		unmetered = readIpList(File.getContent("unmetered.txt"));
		
		while (true) {
			run(a[0], "192.168.1.100", "255.255.255.0", handler);
			
			Lib.println("Reached end, error");
			cpp.Sys.sleep(3);
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
		while (true) { 
			cpp.Sys.sleep(0.500);
			Thread.create(realtime);
		}
	}
	
	public static function realtime():Void {
		valsMutex.acquire();
		var vals = Daemon.vals;
		Daemon.vals = new IntHash();
		valsMutex.release();
		var v: { down:Int , up:Int , uDown:Int , uUp:Int } = {down: 0,up: 0,uDown:0 ,uUp:0};
		for (key in vals.keys()) {
			//Lib.println("Free: " + match(unmetered, key) + "\t" + printIp(key) + "\t" + vals.get(key).down + "\t" + vals.get(key).up);
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
		var out:String = Timer.stamp() + ":" + v.down / 1000 + "," + v.uDown / 1000 + "," + v.up / 1000;// + "," + v.uUp;
		try {
			var realtimeFile:FileOutput = File.write("realtime.txt", false);
			realtimeFile.writeString(out);
			realtimeFile.close();
		} catch (e:Dynamic) {
			trace("From 'realtime'");
		}
	}
	
	public static function outputTiming():Void {
		while (true) { 
			cpp.Sys.sleep(10);
			Thread.create(output);
		}
	}
	
	public static function output():Void {
		//trace("output now");
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
		usernames.add("default");
		var data:List<DataRecord> = new List();
		data.add(dR);
		
		var req = BackendRequest.putData(usernames, data, 3, function(e){});
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
			trace("Filter falure!!\n");
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
	
	private static var run = Lib.load("pcapInterface","run",4);
	private static var listDevices = Lib.load("pcapInterface","listDevices",0);
}
#end