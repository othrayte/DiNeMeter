package webmonitor.master.backend;

import haxe.Md5;
import haxe.Serializer;
import haxe.Unserializer;
import php.Web;
import php.Lib;

import webmonitor.Util;
import webmonitor.Fatal;
import webmonitor.DataRecord;

using webmonitor.TimeUtils;
using webmonitor.Util;
using webmonitor.master.backend.StoredDataRecord;

/**
 *  This file is part of WebMonitorMaster.
 *
 *  WebMonitorMaster is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Affero General Public License as
 *  published by the Free Software Foundation, either version 3 of the
 *  License, or any later version.
 *
 *  WebMonitorMaster is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Affero General Public License for more details.
 *
 *  You should have received a copy of the GNU Affero General Public License
 *  along with WebMonitorMaster.  If not, see <http://www.gnu.org/licenses/>.
 *
 * @author Adrian Cowan (othrayte)
 */

class Controller {
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
				if (!currentUser.can('getdata:'+user.id)) throw new Fatal(UNAUTHORISED(USER_NOT_ALLOWED('getdata', username)));
			}
			"User using specific 'getdata' priveledges of all users listed in the request".log();
		}
		
		var data:Hash<List<DataRecord>> = new Hash();
		
		// Get and store the data records
		for (username in usernames) {
			data.set(username, currentConnection.getUser(username).getData(begining, end, resolution));
		}
		
		queueData(data);
	}
	
	public static function changeData(params:Hash<Dynamic>) {
		
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
				if (!currentUser.can('putdata:'+user.id)) throw new Fatal(UNAUTHORISED(USER_NOT_ALLOWED('putData', username)));
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
				var limitTotal:DataRecord = new DataRecord();
				for (username in usernames) {
					var dR = webmonitor.DataRecord.total(records.get(username),dataRecord.start, dataRecord.end);
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
	}
	
	
	public static function getStatistic(params) {
		
	}
	
	
	public static function readSetting(params) {
		
	}
	
	public static function changeSetting(params) {
		
	}
	
	public static function addUser(params) {
		
	}
	
	public static function removeUser(params) {
		
	}
	
	public static function addConnection(params) {
		
	}
	
	public static function removeConnection(params) {
		
	}
	
	public static function initSession() {
		currentUser.sessionIp = Web.getClientIP();
		currentUser.sessionId = Md5.encode(Std.string(Std.random(99999)) + Std.string(Std.random(99999)) + Std.string(Std.random(99999)) + Std.string(Std.random(99999)));
		currentUser.sessionTimeout = Std.int(DateTools.delta(Date.now(), 60*60).getTime()); // Session times out in one hour;
		currentUser.update();
		queueData(currentUser.sessionId);
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
	
	private static function queueData(data:Dynamic):Void {
		var item:String = Serializer.run(data);
		out.push(item);
	}
	
	public static function pasteData() {
		for (item in out) {
			Lib.println(item);
		}
	}
}