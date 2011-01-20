package webmonitormaster;

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
			var dbVersion:Int = Version.manager.all(false).first().version;
			if (dbVersion != dbVersionReq) {
				if (FileSystem.exists("./dbUpgrade." + dbVersion)) {
					var upgrade:FileInput = File.read("./dbUpgrade." + dbVersion, false);
					// Newer version avaliable
				}
				// DB Version out of date, get newer version
				throw new Fatal(500, "server error: DB version too old and no updates found");
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
				
			}
			
			// close the connection and do some cleanup
			php.db.Manager.cleanup();
			cnx.close();
		
		} catch (message:String) {
			// Deal with connection failure
			Util.debug("Major error: "+message);
		} catch (e:Fatal) {
			Web.setReturnCode(e.code);
			Lib.println(e.message);
			Lib.println("<br />\n<br />\nDebug log:<br />");
			Util.splurt();
		}
	}

}

class Util {
	static var messages:List<String> = new List();
	public static inline function debug(m:Dynamic) {
		#if debug
			messages.push(m);
		#end
	}
	
	public static function splurt() {
		for (message in messages) {
			Lib.println(message+"<br />");
		}
	}
}