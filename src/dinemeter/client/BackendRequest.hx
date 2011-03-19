package dinemeter.client;
import dinemeter.Fatal;
import haxe.Http;
import haxe.Md5;
import haxe.Serializer;
import haxe.Unserializer;
import dinemeter.crypto.Tea;

/**
 *  This file is part of DiNeMeter.
 *
 *  DiNeMeter is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Affero General Public License as
 *  published by the Free Software Foundation, either version 3 of the
 *  License, or any later version.
 *
 *  DiNeMeter is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Affero General Public License for more details.
 *
 *  You should have received a copy of the GNU Affero General Public License
 *  along with DiNeMeter.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * @author Adrian Cowan (Othrayte)
 */

class BackendRequest extends Http {
	#if js
	static public var url:String = "/";
	#elseif cpp
	static public var url:String = "http://www.example.com/";
	#end
	static private var username:String = null;
	static private var sessionId:String = null;
	static private var password:String = null;
	static public var hasCred:Bool = false;
	
	public var onReply:Array<Dynamic>->Void;
	
	// This function must use 'usePassword' or 'useSessionId' to fill in any
	// missing credentials
	public static var requestCred:(Void->Void)->Void; 
	
	public function new() {
		super(BackendRequest.url);
		onError = error;
		onData = responce;
	}
	
	static public function usePassword(password:String, ?username:String) {
		BackendRequest.password = password;
		if (username != null) BackendRequest.username = username;
		BackendRequest.sessionId = null;
		hasCred = (password != null);
	}
	
	static public function useSessionId(sessionId:String, ?username:String) {
		BackendRequest.sessionId = sessionId;
		if (username != null) BackendRequest.username = username;
		BackendRequest.password = null;
		hasCred = (sessionId != null);
	}
	
	static public function checkCreds(f:Bool->Void) {
		var req = new Http(BackendRequest.url);
		req.setParameter("username", username);
		var key:String = password;
		if (sessionId != null) {
			req.setParameter("session", "true");
			key = sessionId;
		}
		var s1:String = Md5.encode(Std.string(Date.now().getTime()));
		var credentials:String = Tea.encrypt(s1 + ":" + Md5.encode(s1), key);
		req.setParameter("cred", credentials);
		req.setParameter("action", "checkcreds");
		#if js
		req.async = true;
		#end
		req.onError = error;
		req.onData = function (responce) {
			if (responce == null) {
				if (f != null) f(true);
				return;
			}
			var data:Array<String> = responce.split("\n");
			var out:Array<Dynamic> = new Array();
			try {
				for (item in data) {
					if (item == "") continue;
					out.push(Unserializer.run(item));
				}
			} catch (e:Fatal) {
				switch (e.type) {
					case UNAUTHORISED(spec): 
						if (f != null) f(false);
						return;
					default: trace(e.message);
				}
			}
			if (out[0] && f != null) f(true);
		}
		req.request(false);
	}
	
	static public function initSession(?password:String, ?username:String, f:Array<Dynamic>->Void):BackendRequest {
		if (password != null) usePassword(password, username);
		var req = new BackendRequest();
		req.setParameter("action", "initsession");
		req.onReply = f;
		req.send();
		return req;
	}
	
	static public function getDefaultRange(f:Array<Dynamic>->Void) {
		var req = new BackendRequest();
		req.setParameter("action", "getdefaultrange");
		req.onReply = f;
		req.send();
		return req;
	}
	
	static public function getData(usernames:List<String>, ?begining:Int, ?end:Int, ?resolution:Null<Int> = null, f:Array<Dynamic>->Void) {
		var req = new BackendRequest();
		req.setParameter("action", "getdata");
		var i:Int = 0;
		for (username in usernames)	req.setParameter("usernames[" + i++ +"]", username);
		if (begining != null) req.setParameter("begining", Std.string(begining));
		if (end != null) req.setParameter("end", Std.string(end));
		if (resolution != null) req.setParameter("resolution", Std.string(resolution));
		req.onReply = f;
		req.send();
		return req;
	}
	
	static public function putData(usernames:List<String>, data:List<DataRecord>, trust:Int, f:Array<Dynamic>->Void) {
		var req = new BackendRequest();
		req.setParameter("action", "putdata");
		var i:Int = 0;
		for (username in usernames)	req.setParameter("usernames[" + i++ +"]", username);
		req.setParameter("data", Serializer.run(data));
		req.setParameter("trust", Std.string(trust));
		req.onReply = f;
		req.send();
		return req;
	}
	
	static public function getCurrentIds(f:Array<Dynamic>->Void) {
		var req = new BackendRequest();
		req.setParameter("action", "getcurrentids");
		req.onReply = f;
		req.send();
		return req;
	}
	
	static public function getStatistic(f:Array<Dynamic>->Void) {
		//TODO: Implement the getStatistic funtion properly
		var req = new BackendRequest();
		req.setParameter("action", "getstat");
		req.onReply = f;
		req.send();
		return req;
	}
	
	static public function readPriveledges(usernames:List<String>, f:Array<Dynamic>->Void) {
		//TODO: Implement the readPriveledges funtion properly
		var req = new BackendRequest();
		req.setParameter("action", "readprivs");
		var i:Int = 0;
		for (username in usernames)	req.setParameter("usernames[" + i++ +"]", username);
		req.onReply = f;
		req.send();
		return req;
	}
	
	static public function readSetting(?userIds:Array<Int>, settings:Array<String>, f:Array<Dynamic>->Void) {
		var req = new BackendRequest();
		req.setParameter("action", "readsetting");
		if (userIds != null) {
			var i:Int = 0;
			for (userId in userIds) req.setParameter("userIds[" + i++ +"]", Std.string(userId));
		}
		var i:Int = 0;
		for (setting in settings) {
			req.setParameter("settings["+i+++"]", setting);
		}
		req.onReply = f;
		req.send();
		return req;
	}
	
	override public function onStatus(s:Int) {
		//trace(s);
	}
	
	public function responce(responce:String) {
		if (responce == null) {
			if (onReply != null) onReply(new Array());
			return;
		}
		var data:Array<String> = responce.split("\n");
		var out:Array<Dynamic> = new Array();
		try {
			for (item in data) {
				if (item == "") continue;
				out.push(Unserializer.run(item));
			}
		} catch (e:Fatal) {
			switch (e.type) {
				case UNAUTHORISED(spec):
					switch (spec) {
						case NO_USER(v):
							hasCred = false;
							send();
						case SESSION_IP_WRONG, SESSION_TIMEOUT, INVALID_CRED, INVALID_CRED_STAGE_1, INVALID_CRED_STAGE_2:
							hasCred = false;
							send();
						default: out.push(e);
					}
					return;
				default: trace(e.message);
			}
		}
		if (onReply != null) onReply(out);
	}
	
	static function error(msg:String) {
		trace(msg);
		//trace(responseHeaders);
	}
	
	public function send() {
		if (hasCred) {			
			setParameter("username", username);
			var key:String = password;
			if (sessionId != null) {
				setParameter("session", "true");
				key = sessionId;
			}
			var s1:String = Md5.encode(Std.string(Date.now().getTime()));
			var credentials:String = Tea.encrypt(s1 + ":" + Md5.encode(s1), key);
			setParameter("cred", credentials);
			#if js
			async = true;
			#end
			
			request(false);
		} else {
			requestCred(send);
		}
	}
	
	public static function whenLoggedIn(f:Void->Void) {
		if (hasCred) {			
			f();
		} else {
			requestCred(callback(whenLoggedIn,f));
		}
	}
}