package webmonitor;

import php.io.File;
import php.io.FileOutput;
import php.Lib;
import php.io.FileInput;
import haxe.io.Eof;

import webmonitor.Fatal;

/**
 *  This file is part of WebMonitor.
 *
 *  WebMonitor is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  any later version.
 *
 *  WebMonitor is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with WebMonitor.  If not, see <http://www.gnu.org/licenses/>.
 *
 * @author Adrian Cowan (othrayte)
 */

class Util {
	static var messages:List<String> = new List();
	public static inline function log(m:String) {
		#if debug
			messages.add(m);
		#end
	}
	
	public static function splurt() {
		for (message in messages) {
			Lib.println(message+"<br />");
		}
	}
	
	public static function record(e:Fatal) {
		var logFile:FileOutput = File.append("log.txt", false);
		logFile.writeString("[" + DateTools.format(Date.now(), "%H:%M:%S") + "] (" + e.code + ") " + e.message + "\n");
		for (message in messages) {
			logFile.writeString("[" + DateTools.format(Date.now(), "%H:%M:%S") + "] " + message + "\n");
		}
		messages.clear();
	}
	
	public static function updateDb(file:FileInput, currentVersion:Int, desiredVersion:Int) {
		var executing:Bool = false;
		var oldVersion:Int = currentVersion;
		var nextVersion:Int = currentVersion;
		try {
			do {
				var command:String = nextUpdateCommand(file);
				if (command.charAt(0) == '@') {
					if (executing) {
						// Check last
						var dbVersion:Int = php.db.Manager.cnx.request("SELECT version FROM `Version` LIMIT 1").getIntResult(0);
						if (dbVersion == nextVersion) {
							log("Successfully updated from db version " + oldVersion + " to version " + dbVersion);
							oldVersion = nextVersion;
							php.db.Manager.cnx.commit();
						} else {
							throw new Fatal(SERVER_ERROR(UPDATE_FAILED));
							php.db.Manager.cnx.rollback();
						}
						executing = false;
					}
					// Parse
					var oldV:Int = Std.parseInt(command.substr(1).split(":")[0]);
					var newV:Int = Std.parseInt(command.substr(1).split(":")[1]);
					// Check next
					if (oldV == oldVersion && newV <= desiredVersion) {
						nextVersion = newV;
						executing = true;
						php.db.Manager.cnx.startTransaction();
					}
				} else if (executing) {
					php.db.Manager.cnx.request(command);
				}
			} while (currentVersion < desiredVersion);
		} catch (e:Eof) {
			if (executing) {
				var dbVersion:Int = php.db.Manager.cnx.request("SELECT version FROM `Version` LIMIT 1").getIntResult(0);
				if (dbVersion == nextVersion) {
					Util.log("Successfully updated from db version " + oldVersion + " to version " + dbVersion);
					oldVersion = nextVersion;
					php.db.Manager.cnx.commit();
				} else {
					php.db.Manager.cnx.rollback();
					throw new Fatal(SERVER_ERROR(UPDATE_FAILED_BETWEEN(oldVersion, nextVersion)));
				}
			}
		} catch (e:String ) {
			Util.log("Mysql error: " + e);
		}
	}
	
	private static function nextUpdateCommand(file:FileInput):String {
		var out:String = "";
		var another:Bool;
		do {
			another = true;
			var tmp:String;
			do {
				tmp = StringTools.trim(file.readLine());
			} while (tmp.charAt(0) == '#' || tmp.length == 0);
			out += " " + tmp;
			out = StringTools.ltrim(out);
			if (out.charAt(0) == '@' || out.charAt(out.length - 1) == ';') another = false;
		} while (another);
		return out;
	}
	
}