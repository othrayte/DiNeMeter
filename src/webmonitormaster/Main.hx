package webmonitormaster;

import haxe.Md5;
import haxe.Unserializer;
import php.Lib;
import php.FileSystem;
import php.db.Mysql;
import php.Sys;
import php.Web;
import php.io.File;
import php.io.FileInput;

using webmonitormaster.Util;

/**
 *  This file is part of WebMonitorMaster.
 *
 *  WebMonitorMaster is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  any later version.
 *
 *  WebMonitorMaster is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with WebMonitorMaster.  If not, see <http://www.gnu.org/licenses/>.
 *
 * @author Adrian Cowan (othrayte)
 */

class Main {
	static var dbVersionReq:Int = 1;
	static function main() {	
		//trace(Tea.encrypt(Md5.encode("hello") + ":" + Md5.encode(Md5.encode("hello")), "default"));
		
		// Initialise the connection
		"Initialising the connection".log();
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
			"Validating the database".log();
			
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
					"DB being upgraded to a newer version".log();
					Util.updateDb(update, dbVersion, dbVersionReq);
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
				
				defaultUser.allow("getdata");
			}
			// Switchboard
			"Switchboard receiving".log();
			var params = php.Web.getParams();
			if (params.exists('show')) {
				"Frontend request".log();
				
				
			} else if (params.exists('action')) {
				"Backend request".log();
				var username = params.exists('username') ? params.get('username') : throw new Fatal(401, "Unauthorised - no username supplied");
				var credentials = params.exists('cred') ? params.get('cred') : throw new Fatal(401, "Unauthorised - no user credentials supplied");
				var connection = params.exists('connection') ? Master.getConnection(params.get('connection')) : Master.getConnection();
				
				Master.login(username, credentials, connection);
				
				//makeFake();
				
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
				
				Master.pasteData();
			} else {
				throw new Fatal(400, "Invalid request - no request type specified");
				
			}
			
			// close the connection and do some cleanup
			php.db.Manager.cleanup();
			cnx.close();
		
		} catch (message:String) {
			// Deal with connection failure
			("Major error: "+message).log();
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
	
	static function makeFake() {
		var t:Int = Math.floor(Date.now().getTime()/1000) -60 * 60 * 6;
		var a:DataRecord;
		do {
			a = new DataRecord();
			a.start = t;
			a.end = a.start + 60 * 30 + Math.floor(Math.random() * 60 * 15);
			a.down = Math.floor(Math.random()*10);
			a.up = Math.floor(Math.random()*10);
			a.uDown = Math.floor(Math.random()*10);
			a.uUp = Math.floor(Math.random() * 10);
			a.trust = 3;
			a.userId = Master.currentUser.id;
			a.insert();
			t = a.end;
		} while (a.end < Date.now().getTime()/1000);
	}
	
}
