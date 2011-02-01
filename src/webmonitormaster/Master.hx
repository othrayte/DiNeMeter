package webmonitormaster;

import haxe.Serializer;
import php.Web;
import php.Lib;
import webmonitormaster.Util;

using webmonitormaster.TimeUtils;
using webmonitormaster.Util;

/**
 * ...
 * @author othrayte
 */

class Master {
	public static var currentUser:User;
	public static var currentConnection:Connection;
	public static var out:List<String> = new List();
	
	public static function login(username:String, credentials:String, connection:Connection) {
		var user:User = connection.getUser(username);
		if (user == null) throw new Fatal(401, "Unauthorised - no user named "+username);
		if (!user.checkCredentials(credentials)) throw new Fatal(401, "Unauthorised - credentials not valid");
		currentUser = user;
		currentConnection = connection;
	}
	
	public static function getData(params:Hash<Dynamic>) {
		if (!params.exists('usernames')) throw new Fatal(400, "Invalid request - Must pass usernames to 'getData'");
			
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
				var user:User = currentConnection.getUser(username);
				if (user == null) throw new Fatal(400, "Invalid request - No user '" + username + "' on this connection");
				if (currentUser.can('getdata:'+user.id)) throw new Fatal(401, "Unauthorised - user not granted rights to 'getData' for user '" + username + "'");
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
		if (!params.exists('usernames')) throw new Fatal(400, "Invalid request - Must pass usernames to 'putData'");
		if (!params.exists('data')) throw new Fatal(400, "Invalid request - Must pass some data to 'putData'");
		if (!params.exists('trust')) throw new Fatal(400, "Invalid request - Must pass trust level to 'putData'");
		
		var usernames = Web.getParamValues('usernames');
		var data = Web.getParamValues('data');
		var trustLevel = params.get('trust');
		
		for (item in data) {
			var totals:Hash<DataRecord> = new Hash();
			
			var details = item.split("|");
			var dataRecord = new DataRecord();
			dataRecord.start = Std.parseInt(details[0]);
			dataRecord.end = Std.parseInt(details[0]);
			dataRecord.down = Std.parseInt(details[0]);
			dataRecord.up = Std.parseInt(details[0]);
			dataRecord.uDown = Std.parseInt(details[0]);
			dataRecord.uUp = Std.parseInt(details[0]);
			dataRecord.trust = trustLevel;
			dataRecord.insert();
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
	
	public static function getConnection(?name:String):Connection {
		var connection:Connection;
		if (name!=null) {
			connection = Connection.manager.byName(name);
			if (connection == null) throw new Fatal(400, "Server error - unable to find requested connection");
		} else {
			connection = Connection.manager.get(1);
			if (connection == null) throw new Fatal(500, "Server error - unable to get default connection");
		}
		return connection;
	}
	
	private static function queueData(data:Dynamic):Void {
		var item:String = Serializer.run(data);
		out.push(item);
	}
	
	public static function pasteData() {
		Lib.println("%StartData%<br />");
		for (item in out) {
			Lib.println(item+"<br />");
		}
		Lib.println("%EndData%<br />");
	}
}