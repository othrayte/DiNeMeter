package dinemeter.master.backend;

import dinemeter.DataRecord;
import haxe.Md5;
import haxe.Serializer;
import haxe.Unserializer;
import php.db.Connection;
import php.Lib;
import php.FileSystem;
import php.db.Mysql;
import php.Sys;
import php.Web;
import php.io.File;
import php.io.FileInput;
import dinemeter.crypto.Tea;

import dinemeter.Config;
import dinemeter.Fatal;

using dinemeter.Util;

/**
 *  This file is part of DiNeMeterMaster.
 *
 *  DiNeMeterMaster is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Affero General Public License as
 *  published by the Free Software Foundation, either version 3 of the
 *  License, or any later version.
 *
 *  DiNeMeterMaster is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Affero General Public License for more details.
 *
 *  You should have received a copy of the GNU Affero General Public License
 *  along with DiNeMeterMaster.  If not, see <http://www.gnu.org/licenses/>.
 *
 * @author Adrian Cowan (othrayte)
 */

class Main {
	static var dbVersionReq:Int = 5;
	static var backendConf:Config;
	static function main() {	
        //trace(Tea.rs(untyped -1388413616, 5));
        //trace(Md5.encode("hello") + ":" + Md5.encode(Md5.encode("hello")));
		//trace(Tea.encrypt(Md5.encode("hello") + ":" + Md5.encode(Md5.encode("hello")), "default"));
		//trace(Tea.decrypt(Tea.encrypt(Md5.encode("hello") + ":" + Md5.encode(Md5.encode("hello")), "default"), "default"));
		
		// Reading the config file
		"Reading the config file".log();
		backendConf = new Config("./backend-config.txt");
        Controller.config = backendConf;
		
		// Initialise the db connection
		"Initialising the db connection".log();
		var cnx:Connection;
		try {
			try {
				cnx = php.db.Mysql.connect({ 
					host : backendConf.get("host"),//"localhost",
					port : backendConf.get("host-port"),//3306,
					database : backendConf.get("mysql-database"),//"dinemeterdata",
					user : backendConf.get("mysql-username"),//"wmmaster",
					pass : backendConf.get("mysql-password"),//"wmmaster",
					socket : null
				});
			} catch (msg:String) {
				throw new Fatal(SERVER_ERROR(DB_LOGIN_ERROR(msg)));
			}
			php.db.Manager.cnx = cnx;
			php.db.Manager.initialize();
		
			// Validate the database
			"Validating the database".log();
			php.db.Manager.cnx.request("CREATE TABLE IF NOT EXISTS `version` (`version` INT NOT NULL, `id` INT NOT NULL auto_increment, PRIMARY KEY  (id)) ENGINE=InnoDB");
			if (Version.manager.count() == 0) {
				// Create the verion instance
				"DB empty, initialising".important();
				var current:Version = new Version();
				current.version = 0;
				current.insert();
			}
			
			DbUpdater.updateDb(dbVersionReq);
			
			// Make sure there is at least a default user
			if (StoredUser.manager.count() == 0) {
				var defaultUser:StoredUser = new StoredUser();
				defaultUser.name = 'default';
				defaultUser.password = 'default';
				defaultUser.connectionId = 1;
				defaultUser.insert();
				 
				defaultUser.allow("getdata");
				defaultUser.allow("putdata");
			}
			
			// Switchboard
			"Switchboard receiving".log();
			("Request is: " + Web.getParamsString()).log();
			var params = php.Web.getParams();
			
			// Temporery hack for old WebMonitorWatcher compatability
			if (params.exists('wmwUser')) {
				"Showing backcompatable page for WMW".log();
				bCPFWMW(params.get('wmwUser'));
				return;
			}
            
            // Test cases
			if (backendConf.get("enable-tests") && params.exists('test')) {
                var testName = params.get('test');
				("Test requestd: "+testName).log();
				switch (testName) {
                    case 'refactor_1': Tests.refactor1();
                    default: throw new Fatal(INVALID_REQUEST(INVALID_TEST(testName)));
                }
				return;
			}
            
			if (params.exists('action')) {
				"Backend request".log();
				var username = params.exists('username') ? params.get('username') : throw new Fatal(INVALID_REQUEST(NO_USERNAME_SUPPLIED));
				var credentials = params.exists('cred') ? params.get('cred') : throw new Fatal(INVALID_REQUEST(NO_CRED_SUPPLIED));
				var connection = params.exists('connection') ? Controller.getConnection(params.get('connection')) : Controller.getConnection();
				var session = params.exists('session');
				
				Controller.login(username, credentials, connection, session);
				"Successfully logged in".log();
				//makeFake();
				
				var action = params.get('action').toLowerCase();
				if (action == 'getdefaultrange') {
					Controller.getDefaultRange();
				} else if (action == 'getdata') {
					Controller.getData(params);
				} else if (action == 'changedata') {
					Controller.changeData(params);
				} else if (action == 'putdata') {
					Controller.putData(params);
				} else if (action == 'getcurrentids') {
					Controller.getCurrentIds();
				} else if (action == 'getstat') {
					Controller.getStatistic(params);
				} else if (action == 'readprivs') {
					Controller.readPrivledges(params);
				} else if (action == 'grantpriv') {
					Controller.grantPrivledge(params);
				} else if (action == 'revokepriv') {
					Controller.revokePrivledge(params);
				} else if (action == 'readsetting') {
					Controller.readSetting(params);
				} else if (action == 'changesetting') {
					Controller.changeSetting(params);
				} else if (action == 'adduser') {
					Controller.addUser(params);
				} else if (action == 'removeuser') {
					Controller.removeUser(params);
				} else if (action == 'listusers') {
					Controller.listUsers();
				} else if (action == 'makedaemonsetup') {
					Controller.makeDaemonSetup(params);
				} else if (action == 'reporterror') {
					Controller.reportError(params);
				} else if (action == 'initsession') {
					Controller.initSession();
				} else if (action == 'checkcreds') {
					Controller.queueData(true);
				} else {
					throw new Fatal(INVALID_REQUEST(INVALID_ACTION(action)));
				}
				
				Controller.pasteData();
			} else {
				Controller.embedPage();
			}
			
			// close the connection and do some cleanup
			php.db.Manager.cleanup();
			cnx.close();
		
		} catch (message:String) {
			// Deal with connection failure
			("Major error: "+message).important();
		} catch (e:Fatal) {
			if (php.Web.getParams().exists('block')||php.Web.getParams().exists('action'))  {
				var s = new Serializer();
				s.serializeException(e);
				Lib.print(s);
			} else {
				Lib.print("This website has experienced an error, please try again later.<br />\nDetails: (" + e.code + ") " + e.message);
			}
			Util.record(e);
			return;
		}
		Util.flush(true);
	}
	
	static function makeFake() {
		var t:Int = Math.floor(Date.now().getTime()/1000) -60 * 60 * 6;
		var a:StoredDataRecord;
		do {
			a = new StoredDataRecord();
			a.start = t;
			a.end = a.start + 60 * 30 + Math.floor(Math.random() * 60 * 15);
			a.down = Math.floor(Math.random()*10);
			a.up = Math.floor(Math.random()*10);
			a.uDown = Math.floor(Math.random()*10);
			a.uUp = Math.floor(Math.random() * 10);
			a.trust = 3;
			a.userId = Controller.currentUser.id;
			a.insert();
			t = a.end;
		} while (a.end < Date.now().getTime()/1000);
	}
	
	static function bCPFWMW(username:String) {
		var totalLeft:Float;
		var totalLeftPDay:Float;
		var downloadedM:Float;
		var downloadedUM:Float;
		var uploaded:Float;
		var avgDLRate:Float;
		
		var connection = Controller.getConnection();
		var user = connection.getUser(username);
		
		if (user == null) return;
		
		var start = dinemeter.TimeUtils.getStandardBegining(connection);
		var now = dinemeter.TimeUtils.getStandardEnd(connection);
		var end = dinemeter.TimeUtils.getMonthEnd(connection);
		
		var data:DataRecord = DataRecord.total(user.getData(start, now), start, now);
		
		totalLeft = user.downQuota - data.down;
		if (totalLeft < 0) totalLeft = 0;
		
		totalLeftPDay = totalLeft / ((end - now) / 86400);
		
		downloadedM = data.down;
		
		downloadedUM = data.uDown;
		
		uploaded = data.uUp;
		
		avgDLRate = data.down / ((now - start) / 86400);
		
		Lib.print(dinemeter.DataMath.format(totalLeft) + "," + dinemeter.DataMath.format(totalLeftPDay) + "," + dinemeter.DataMath.format(downloadedM) + "," + dinemeter.DataMath.format(downloadedUM) + "," + dinemeter.DataMath.format(uploaded) + "," + dinemeter.DataMath.format(avgDLRate));
		Util.flush(true);
	}
}
