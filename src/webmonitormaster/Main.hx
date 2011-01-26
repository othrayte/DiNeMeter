package webmonitormaster;

import haxe.io.Eof;
import haxe.Md5;
import php.db.Mysql;
import php.FileSystem;
import php.io.File;
import php.io.FileInput;
import php.Lib;
import php.Sys;
import php.Web;

/**
 * ...
 * @author othrayte
 */

class Main {
	static var dbVersionReq:Int = 1;
	static function main() {	
		trace(Tea.encrypt(Md5.encode("hello") + ":" + Md5.encode(Md5.encode("hello")), "default"));
		// Initialise the connection
		Util.debug("Initialising the connection");
		var cnx:php.db.Connection;
		try {
			cnx = php.db.Mysql.connect({ 
				host : "localhost",
				port : 3306,
				database : "webmonitordata",
				user : "wmmaster",
				pass : "wmmaster",
				socket : null
			});
		
			php.db.Manager.cnx = cnx;
			php.db.Manager.initialize();
		
			// Validate the database
			Util.debug("Validating the database");
			
			php.db.Manager.cnx.request("CREATE TABLE IF NOT EXISTS `version` (`version` INT NOT NULL, `id` INT NOT NULL auto_increment, PRIMARY KEY  (id)) ENGINE=InnoDB");
			if (Version.manager.count() == 0) {
				// Create the verion instance
				var current:Version = new Version();
				current.version = 0;
				current.insert();
			}
			if (Version.manager.count() == 0) throw new Fatal(500, "server error: unknown databse version");
			var dbVersion:Int = php.db.Manager.cnx.request("SELECT version FROM `Version` LIMIT 1").getIntResult(0);
			if (dbVersion != dbVersionReq) {
				if (FileSystem.exists("./updates/db/" + dbVersion + ".wmdbupdate")) {
					var update:FileInput = File.read("./updates/db/" + dbVersion + ".wmdbupdate", false);
					// Newer version avaliable
					Util.debug("DB being upgraded to a newer version");
					Util.updateDB(update, dbVersion, dbVersionReq);
				}
			}
			dbVersion = php.db.Manager.cnx.request("SELECT version FROM `Version` LIMIT 1").getIntResult(0);
			if (dbVersion != dbVersionReq) {
				throw new Fatal(500, "server error: DB version too old");
			}
			
			// Make sure there is at least a default user
			if (User.manager.count() == 0) {
				var defaultUser:User = new User();
				defaultUser.name = 'default';
				defaultUser.password = 'default';
				defaultUser.connectionId = 1;
				defaultUser.insert();
			}
			
			// Switchboard
			Util.debug("Switchboard receiving");
			var params = php.Web.getParams();
			if (params.exists('show')) {
				Util.debug("Frontend request");
				
				
			} else if (params.exists('action')) {
				Util.debug("Backend request");
				var username = params.exists('username') ? params.get('username') : throw new Fatal(401, "Unauthorised - no username supplied");
				var credentials = params.exists('cred') ? params.get('cred') : throw new Fatal(401, "Unauthorised - no user credentials supplied");
				var connection = params.exists('connection') ? Master.getConnection(params.get('connection')) : Master.getConnection();
				
				Master.login(username, credentials, connection);
				
				var action = params.get('action').toLowerCase();
				if (action == 'getdata') {
					Master.getData(params);
				} else if (action == 'changedata') {
					Master.changeData(params);
				} else if (action == 'setdata') {
					Master.putData(params);
				} else if (action == 'putstats') {
					Master.getStatistic(params);
				} else if (action == 'readsetting') {
					Master.readSetting(params);
				} else if (action == 'changesetting') {
					Master.changeSetting(params);
				}
				
			} else {
				throw new Fatal(400, "Invalid request - no request type specified");
				
			}
			
			// close the connection and do some cleanup
			php.db.Manager.cleanup();
			cnx.close();
		
		} catch (message:String) {
			// Deal with connection failure
			Util.debug("Major error: "+message);
		} catch (e:Fatal) {
			Web.setReturnCode(e.code);
			Lib.println("<span style='color: red;'>");
			Lib.println("<strong>"+e.code+"</strong>");
			Lib.println(e.message);
			Lib.println("</span>");
			Lib.println("<br />\n<br />\nDebug log:<br />");
			Util.splurt();
			return;
		}
		
		Lib.println("<span style='color: green;'>");
		Lib.println("<br />\n<br />\nDebug log:<br />");
		Util.splurt();
		Lib.println("</span>");
	}

}

class Util {
	static var messages:List<String> = new List();
	public static inline function debug(m:Dynamic) {
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
	
	public static function updateDB(file:FileInput, currentVersion:Int, desiredVersion:Int) {
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
							Util.debug("Successfully updated from db version " + oldVersion + " to version " + dbVersion);
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
					Util.debug("Successfully updated from db version " + oldVersion + " to version " + dbVersion);
					oldVersion = nextVersion;
					php.db.Manager.cnx.commit();
				} else {
					php.db.Manager.cnx.rollback();
					throw new Fatal(500, "server error: update failed from db version " + oldVersion + " to version " + nextVersion);
				}
			}
		} catch (e:String ) {
			Util.debug("Mysql error: " + e);
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