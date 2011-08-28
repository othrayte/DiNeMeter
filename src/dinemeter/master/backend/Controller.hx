package dinemeter.master.backend;

import dinemeter.IUser;
import dinemeter.Priveledge;
import haxe.Md5;
import haxe.Serializer;
import haxe.Unserializer;
import php.FileSystem;
import php.io.File;

#if php
import php.Web;
import php.Lib;
#end

import dinemeter.Util;
import dinemeter.Fatal;
import dinemeter.DataList;
import dinemeter.DataRecord;

using dinemeter.Config;
using dinemeter.TimeUtils;
using dinemeter.Util;
using dinemeter.master.backend.StoredDataRecord;
using Lambda;

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

class Controller {
    public static var config:Config;
	public static var currentUser:StoredUser;
	public static var currentConnection:StoredConnection;
	public static var out:List<String> = new List();
	
	public static function login(username:String, credentials:String, connection:StoredConnection, ?session:Bool = false) {
		var user:StoredUser = connection.getUser(username);
		if (user == null) throw new Fatal(UNAUTHORISED(NO_USER(username)));
		if (!user.checkCredentials(credentials, session)) throw new Fatal(UNAUTHORISED(INVALID_CRED));
		currentUser = user;
		currentConnection = connection;
	}
	
	public static function getDefaultRange() {
		queueData(currentConnection.getStandardBegining());
		queueData(currentConnection.getStandardEnd());
		queueData(currentConnection.getMonthEnd());
	}
	
	public static function getData(params:Hash<Dynamic>) {
		if (!params.exists('usernames')) throw new Fatal(INVALID_REQUEST(MISSING_USERNAMES("getData")));
			
		var usernames = Web.getParamValues('usernames');
		var begining:Int  = params.exists('begining') ? params.get('begining') : currentConnection.getStandardBegining();
		var end:Int = params.exists('end') ? params.get('end') : currentConnection.getStandardEnd();
		var resolution:Int = params.exists('resolution') ? params.get('resolution') : 0;
		
		var downloads:Bool = params.exists('downloads') ? params.get('downloads') : true;
		var uploads:Bool = params.exists('uploads') ? params.get('uploads') : true;
		var unmeteredDownloads:Bool = params.exists('unmeteredDownloads') ? params.get('unmeteredDownloads') : true;
		var unmeteredUploads:Bool = params.exists('unmeteredUploads') ? params.get('unmeteredUploads') : true;
		
		// Check the passed usernames are valid and that the user has the correct rights to access their data
		if (currentUser.can('getdata')) {
			"User using general 'getdata' priveledges".log();
		} else {
			for (username in usernames) {
				var user:IUser = currentConnection.getUser(username);
				if (user == null) throw new Fatal(INVALID_REQUEST(USER_NOT_IN_CONNECTION(username)));
				if (!currentUser.can('getdata', Std.string(user.id))) throw new Fatal(UNAUTHORISED(USER_NOT_ALLOWED('getdata', username)));
			}
			"User using specific 'getdata' priveledges of all users listed in the request".log();
		}
		
		var data:Hash<DataList<DataRecord>> = new Hash();
		// Get and store the data records
		for (username in usernames) {
			data.set(username, currentConnection.getUser(username).getData(begining, end, resolution));
		}
        
		queueData(data);
	}
	
	public static function changeData(params:Hash<Dynamic>) {
		throw new Fatal(SERVER_ERROR(NOT_IMPLEMENTED("changeData")));
	}
	
	public static function putData(params:Hash<Dynamic>) {
		if (!params.exists('usernames')) throw new Fatal(INVALID_REQUEST(MISSING_USERNAMES('putData')));
		if (!params.exists('data')) throw new Fatal(INVALID_REQUEST(MISSING_DATA('putData')));
		if (!params.exists('trust')) throw new Fatal(INVALID_REQUEST(MISSING_TRUST_LEVEL('putData')));
		
		var usernames = Web.getParamValues('usernames');
		var data:List<DataRecord>;
		try {
			data = Unserializer.run(params.get('data'));
		} catch (e:Dynamic) {
			// Catch any exceptions that might be sent our way and return them in kind
			throw new Fatal(INVALID_REQUEST(INVALID_DATA('putdata')));
		}
		var trustLevel = params.get('trust');
		//TODO: Implement some kind of priveleges for putting with a trust level
		
		// Check the passed usernames are valid and that the user has the correct rights to insert the data
		if (currentUser.can('putdata')) {
			"User using general 'putdata' priveledges".log();
		} else {
			for (username in usernames) {
				var user:IUser = currentConnection.getUser(username);
				if (user == null) throw new Fatal(UNAUTHORISED(NO_USER(username)));
				if (!currentUser.can('putdata', Std.string(user.id))) throw new Fatal(UNAUTHORISED(USER_NOT_ALLOWED('putData', username)));
			}
			"User using specific 'putdata' priveledges for each of the users listed in the request".log();
		}
		if (usernames.length > 1) {			
			var first:Int = data.first().start;
			var last:Int = data.last().end;
			for (dataRecord in data) {
				if (dataRecord.start < first) first = dataRecord.start;
				if (dataRecord.end > last) last = dataRecord.end;
			}
			var records:Hash<List<DataRecord>> = new Hash();
			for (username in usernames) {
				records.set(username, currentConnection.getUser(username).getData(first, last));
			}
			for (dataRecord in data) {
				var totals:Hash<DataRecord> = new Hash();
				var grandTotal:DataRecord = new DataRecord();
				var limitTotal:{down:Float, up:Float} = {down: 0., up:0.};
				for (username in usernames) {
					var dR = dinemeter.DataRecord.total(records.get(username),dataRecord.start, dataRecord.end);
					totals.set(username, dR);
					grandTotal.down += dR.down;
					grandTotal.up += dR.up;
					grandTotal.uDown += dR.uDown;
					grandTotal.uUp += dR.uUp;
					limitTotal.down += currentConnection.getUser(username).downQuota;
					limitTotal.up += currentConnection.getUser(username).upQuota;
				}
				for (username in usernames) {
					var dR:StoredDataRecord = new StoredDataRecord();
					var uTotals = totals.get(username);
					if (limitTotal.down == 0) {
						dR.down = Math.round(dataRecord.down / usernames.length);
					} else if (grandTotal.down == 0) {
						dR.down = Math.round(dataRecord.down / (limitTotal.down / currentConnection.getUser(username).downQuota));
					} else if (uTotals.down > 0) {
						dR.down = Math.round(dataRecord.down / (grandTotal.down / uTotals.down));
					}
					if (limitTotal.up == 0) {
						dR.up = Math.round(dataRecord.up / usernames.length);
					} else if (grandTotal.down == 0) {
						dR.up = Math.round(dataRecord.up / (limitTotal.up / currentConnection.getUser(username).upQuota));
					} else if (uTotals.up > 0) {
						dR.up = Math.round(dataRecord.up / (grandTotal.up / uTotals.up));
					}
					if (grandTotal.uDown == 0) {
						dR.uDown = Math.round(dataRecord.uDown / usernames.length);
					} else if (uTotals.uDown > 0) {
						dR.uDown = Math.round(dataRecord.uDown / (grandTotal.uDown / uTotals.uDown));
					}
					if (grandTotal.uUp == 0) {
						dR.uUp = Math.round(dataRecord.uUp / usernames.length);
					} else if (uTotals.uUp > 0) {
						dR.uUp = Math.round(dataRecord.uUp / (grandTotal.uUp / uTotals.uUp));
					}
					
					dR.start = dataRecord.start;
					dR.end = dataRecord.end;
					dR.trust = trustLevel;
					dR.userId = currentConnection.getUser(username).id;
					dR.insert();
				}
			}
		} else {
			var userId = currentConnection.getUser(usernames[0]).id;
			for (item in data) {
				var dataRecord = StoredDataRecord.createFrom(item);				
				dataRecord.trust = trustLevel;
				dataRecord.userId = userId;
				dataRecord.insert();
			}
		}
        currentConnection.refactorArchive();
	}
	
	public static function getCurrentIds() {
		queueData(currentConnection.id);
		queueData(currentUser.id);
	}
	
	public static function getStatistic(params) {
		throw new Fatal(SERVER_ERROR(NOT_IMPLEMENTED("getStatistic")));
	}
	
	public static function readPrivledges(params) {
		if (!params.exists('usernames')) throw new Fatal(INVALID_REQUEST(MISSING_USERNAMES("readPrivledges")));
		
		var usernames:Array<String> = Web.getParamValues('usernames');
		if (usernames == null) throw new Fatal(SERVER_ERROR(LOGIC_BOMB));
		
		if (currentUser.can('readpriv')) {
			"User using general 'readpriv' priveledges".log();
		} else {
			for (username in usernames) {
				var user:IUser = currentConnection.getUser(username);
				if (user == null) throw new Fatal(INVALID_REQUEST(USER_NOT_IN_CONNECTION(username)));
				if (!currentUser.can('readpriv', Std.string(user.id))) throw new Fatal(UNAUTHORISED(USER_NOT_ALLOWED('readpriv', username)));
			}
			"User using specific 'readpriv' priveledges of all users listed in the request".log();
		}
		
		var out:Hash<Hash<Priveledge>> = new Hash();
		for (username in usernames) {
			var out2:Hash<Priveledge> = new Hash();
			var user:IUser = currentConnection.getUser(username);
			var list = StoredPriveledge.manager.getAllFor(user);
			for (item in list) {
				out2.set(item.name+":"+item.target, Priveledge.fromStoredPriveledge(item));
			}
			out.set(username, out2);
		}
		queueData(out);
	}
	
	public static function grantPrivledge(params) {
		throw new Fatal(SERVER_ERROR(NOT_IMPLEMENTED("grantPrivledge")));
	}
	
	public static function revokePrivledge(params) {
		throw new Fatal(SERVER_ERROR(NOT_IMPLEMENTED("revokePrivledge")));
	}
	
	public static function readSetting(params) {
		if (!params.exists('settings')) throw new Fatal(INVALID_REQUEST(MISSING_SETTINGS('readSetting')));
		
		var userIds:Array<Int> = params.exists('userIds') ? Web.getParamValues('userIds').map(Std.parseInt).array() : [currentUser.id];
		var settings:Array<String> = Web.getParamValues('settings');
		
		if (currentUser.can('readsetting') || currentUser.can('changesetting')) {
			"User using general 'readsetting' priveledges".log();
		} else {
			for (userId in userIds) {
				var user:IUser = currentConnection.getUser(userId);
				if (user == null) throw new Fatal(INVALID_REQUEST(USER_NOT_IN_CONNECTION(Std.string(userId))));
				if (currentUser.id != userId && !currentUser.can('changesetting', Std.string(userId)) && !currentUser.can('readsetting', Std.string(userId))) throw new Fatal(UNAUTHORISED(USER_NOT_ALLOWED('readsetting', Std.string(userId))));
			}
			"User using specific 'readsetting' priveledges of all users listed in the request".log();
		}
		
		var out:IntHash<Hash<Dynamic>> = new IntHash();
		
		for (userId in userIds) {
			var out2:Hash<Dynamic> = new Hash();
			for (setting in settings) {
				switch (setting) {
					case "upQuota": out2.set(setting, currentConnection.getUser(userId).upQuota);
					case "downQuota": out2.set(setting, currentConnection.getUser(userId).downQuota);
					case "downMetered": out2.set(setting, (cast currentConnection.downMetered) == 1);
					case "upMetered": out2.set(setting, (cast currentConnection.upMetered) == 1);
					default: throw new Fatal(INVALID_REQUEST(INVALID_SETTING(setting)));
				}
			}
			out.set(userId, out2);
		}
		queueData(out);
	}
	
	public static function changeSetting(params:Hash<Dynamic>) {        
		if (!params.exists('settings')) throw new Fatal(INVALID_REQUEST(MISSING_SETTINGS('changeSetting')));
		
		if (!params.exists('userId')) throw new Fatal(INVALID_REQUEST(MISSING_PARAM('userId', 'removeUser')));
        var userId:Int = params.get('userId');
        
		var settings:Hash<Dynamic> = Unserializer.run(params.get('settings'));
        
		if (!currentUser.can('changesetting', Std.string(userId))) throw new Fatal(UNAUTHORISED(USER_NOT_ALLOWED('changesetting', Std.string(userId))));
		
        var user = StoredUser.manager.get(userId);
        for (name in settings.keys()) {
            switch (name) {
                case "upQuota": user.upQuota = settings.get(name);
                case "downQuota": user.downQuota = settings.get(name);
                case "name": user.name = settings.get(name);
                case "password": user.password = settings.get(name);
                default: throw new Fatal(INVALID_REQUEST(INVALID_SETTING(name)));
            }
        }
        user.update();
		queueData(true);
	}
	
	public static function addUser(params:Hash<Dynamic>) {
		if (!currentUser.can("adduser")) throw new Fatal(UNAUTHORISED(USER_NOT_GRANTED('adduser')));
		
		if (!params.exists('connectionId')) throw new Fatal(INVALID_REQUEST(MISSING_PARAM('connectionId','addUser')));
		if (!params.exists('newName')) throw new Fatal(INVALID_REQUEST(MISSING_PARAM('newName','addUser')));
		if (!params.exists('newPassword')) throw new Fatal(INVALID_REQUEST(MISSING_PARAM('newPassword','addUser')));
		if (!params.exists('downQuota')) throw new Fatal(INVALID_REQUEST(MISSING_PARAM('downQuota','addUser')));
		if (!params.exists('upQuota')) throw new Fatal(INVALID_REQUEST(MISSING_PARAM('upQuota','addUser')));
		
		var connectionId:Int = Std.parseInt(params.get('connectionId'));
		var newName:String = params.get('newName');
		var newPassword:String = params.get('newPassword');
		var downQuota:Float = Std.parseFloat(params.get('downQuota'));
		var upQuota:Float = Std.parseFloat(params.get('upQuota'));
		
		var newUser:StoredUser = new StoredUser();
		newUser.name = newName;
		newUser.password = newPassword;
		newUser.downQuota = downQuota;
		newUser.upQuota = upQuota;
		newUser.connectionId = connectionId;
		newUser.insert();
		
		queueData( { name: newUser.name, id: newUser.id } );
	}
	
	public static function removeUser(params:Hash<Dynamic>) {
		if (!currentUser.can("removeuser")) throw new Fatal(UNAUTHORISED(USER_NOT_GRANTED('removeuser')));
		
		if (!params.exists('userId')) throw new Fatal(INVALID_REQUEST(MISSING_PARAM('userId', 'removeUser')));
		
		var userId:Int = params.get('userId');
		StoredUser.manager.get(userId).delete();
	}
	
	public static function listUsers() {
		if (!currentUser.can('listusers')) throw new Fatal(UNAUTHORISED(USER_NOT_GRANTED('listusers')));
		
		var users:List<{name:String, id:Int}> = StoredUser.manager.all().map(function (user:StoredUser) {
			return {name: user.name, id:user.id};
		});
		queueData(users);
	}
	
	public static function makeDaemonSetup(params:Hash<Dynamic>) {
		if (!currentUser.can('makedaemonsetup')) throw new Fatal(UNAUTHORISED(USER_NOT_GRANTED('makedaemonsetup')));
        
		if (!params.exists('userId')) throw new Fatal(INVALID_REQUEST(MISSING_PARAM('userId', 'makeDaemonSetup')));
		
        var userId:Int = params.get('userId');
        var user = StoredUser.manager.get(userId);
        var path = Web.getHostName()+Web.getURI();
        path = path.substr(0, path.lastIndexOf("/") + 1);
        var filename = "DaemonSetup[" + StringTools.replace(Serializer.run("http://" + path + "," + user.name), ":", ";") + "].exe";
        File.copy("DaemonSetup.exe", filename);
		
        var out = "http://" + path + StringTools.urlEncode(filename);
		queueData(out);
	}
    
	public static function reportError(params:Hash<Dynamic>) {
		if (!params.exists('type')) throw new Fatal(INVALID_REQUEST(MISSING_PARAM('type', 'reportError')));
		if (!params.exists('message')) throw new Fatal(INVALID_REQUEST(MISSING_PARAM('message', 'reportError')));
        
        try {
            var err = Unserializer.run(params.get('type'));
            // May in future allow different types of reporting based on the error reported
            "Error reported from client".important();
            emailAdmin(params.get('message'));
        } catch (e:Dynamic) {
            new Fatal(INVALID_REQUEST(INVALID_PARAM("type","reportError")));
        }
	}
    
	public static function addConnection(params) {
		throw new Fatal(SERVER_ERROR(NOT_IMPLEMENTED("addConnection")));
	}
	
	public static function removeConnection(params) {
		throw new Fatal(SERVER_ERROR(NOT_IMPLEMENTED("removeConnection")));
	}
	
	public static function initSession() {
		currentUser.sessionIp = Web.getClientIP();
		currentUser.sessionId = Md5.encode(Std.string(Std.random(99999)) + Std.string(Std.random(99999)) + Std.string(Std.random(99999)) + Std.string(Std.random(99999)));
		currentUser.sessionTimeout = Std.int(DateTools.delta(Date.now(), 60*60).getTime()); // Session times out in one hour;
		currentUser.update();
		queueData(currentUser.sessionId);
	}
	
	public static function embedPage() {
		Lib.printFile("frontend.html");
	}
    
    static function emailAdmin(message:String) {
        if (config != null) {
            var email:String;
            if ((email = config.get("admin-email")) != null) {
				untyped __php__("try {");
                untyped __call__('mail', email, '[DiNeMeter] Error report', message);
				untyped __php__("} catch (Exception $e){");
				"Unable to send email, check your servers settings".important();
				untyped __php__("}");
                "Sent email to admin".important();
                return;
            }
        }
        "Unable to email admin".important();
    }
	
	public static function getConnection(?name:String):StoredConnection {
		var connection:StoredConnection;
		if (name!=null) {
			connection = StoredConnection.manager.byName(name);
			if (connection == null) throw new Fatal(INVALID_REQUEST(CONNECTION_NOT_FOUND));
		} else {
			connection = StoredConnection.manager.get(1);
			if (connection == null) throw new Fatal(SERVER_ERROR(DEFAULT_CONNECTION_MISSING));
		}
		return connection;
	}
	
	public static function queueData(data:Dynamic):Void {
        try {
            var item:String = Serializer.run(data);
            out.add(item);
        }
        catch (e:Dynamic) {
            throw new Fatal(SERVER_ERROR(INTERNAL("Unable to serialize data for return journey")));
        }
	}
	
	public static function pasteData() {
		for (item in out) {
			Lib.println(item);
		}
	}
}