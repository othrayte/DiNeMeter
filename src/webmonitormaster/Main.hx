package webmonitormaster;

import haxe.Md5;
import haxe.Serializer;
import haxe.Unserializer;
import php.Lib;
import php.FileSystem;
import php.db.Mysql;
import php.Sys;
import php.Web;
import php.io.File;
import php.io.FileInput;

import webmonitormastergui.MasterGui;
import webmonitormaster.Fatal;

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
	static var dbVersionReq:Int = 2;
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
				"DB empty, initialising".log();
				var current:Version = new Version();
				current.version = 0;
				current.insert();
			}
			if (Version.manager.count() == 0) throw new Fatal(SERVER_ERROR(UNKNOWN_DB_VERSION));
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
				throw new Fatal(SERVER_ERROR(DB_VERSION_OLD));
			}
			
			// Make sure there is at least a default user
			if (User.manager.count() == 0) {
				var defaultUser:User = new User();
				defaultUser.name = 'default';
				defaultUser.password = 'default';
				defaultUser.connectionId = 1;
				defaultUser.insert();
				
				defaultUser.allow("getdata");
				defaultUser.allow("putdata");
			}
			// Switchboard
			"Switchboard receiving".log();
			var params = php.Web.getParams();
			if (params.exists('block')) {
				"Frontend request".log();
				MasterGui.embed(params.get('block'));				
			} else if (params.exists('action')) {
				"Backend request".log();
				var username = params.exists('username') ? params.get('username') : throw new Fatal(INVALID_REQUEST(NO_USERNAME_SUPPLIED));
				var credentials = params.exists('cred') ? params.get('cred') : throw new Fatal(INVALID_REQUEST(NO_CRED_SUPPLIED));
				var connection = params.exists('connection') ? Master.getConnection(params.get('connection')) : Master.getConnection();
				var session = params.exists('session');
				
				Master.login(username, credentials, connection, session);
				"Successfully logged in".log();
				//makeFake();
				
				var action = params.get('action').toLowerCase();
				if (action == 'getdata') {
					Master.getData(params);
				} else if (action == 'changedata') {
					Master.changeData(params);
				} else if (action == 'putdata') {
					Master.putData(params);
				} else if (action == 'putstats') {
					Master.getStatistic(params);
				} else if (action == 'readsetting') {
					Master.readSetting(params);
				} else if (action == 'changesetting') {
					Master.changeSetting(params);
				} else if (action == 'initsession') {
					Master.initSession();
				} else {
					throw new Fatal(INVALID_REQUEST(INVALID_ACTION(action)));
				}
				
				Master.pasteData();
			} else {
				MasterGui.embed('start');
			}
			
			// close the connection and do some cleanup
			php.db.Manager.cleanup();
			cnx.close();
		
		} catch (message:String) {
			// Deal with connection failure
			("Major error: "+message).log();
		} catch (e:Fatal) {
			Web.setReturnCode(e.code); //This can show unwanted messages on the console when the user credentials are wrong
			var s = new Serializer();
			s.serializeException(e);
			Lib.print(s);
			Util.record(e);
			return;
		}
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
