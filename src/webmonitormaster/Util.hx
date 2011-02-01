package webmonitormaster;

import php.Lib;
import php.io.FileInput;
import haxe.io.Eof;

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
							throw new Fatal(500, "server error: update failed");
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
					throw new Fatal(500, "server error: update failed from db version " + oldVersion + " to version " + nextVersion);
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