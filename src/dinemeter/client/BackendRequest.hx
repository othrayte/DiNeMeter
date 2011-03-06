package dinemeter.client;
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
	static public var username:String;
	static public var sessionId:String;
	static public var password:String;
	
	public var onReply:List<Dynamic>->Void;
	
	public function new() {
		super(BackendRequest.url);
		onData = responce;
		onError = error;
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
	}
	
	static public function usePassword(password:String, ?username:String) {
		BackendRequest.password = password;
		if (username != null) BackendRequest.username = username;
		BackendRequest.sessionId = null;
	}
	
	static public function useSessionId(sessionId:String, ?username:String) {
		BackendRequest.sessionId = sessionId;
		if (username != null) BackendRequest.username = username;
		BackendRequest.password = null;
	}
	
	static public function initSession(?password:String, ?username:String, f:List<Dynamic>->Void):BackendRequest {
		if (password != null) usePassword(password, username);
		var req = new BackendRequest();
		req.setParameter("action", "initsession");
		req.onReply = f;
		req.send();
		return req;
	}
	
	static public function getData(usernames:List<String>, begining:Int, end:Int, ?resolution:Null<Int> = null, f:List<Dynamic>->Void) {
		var req = new BackendRequest();
		req.setParameter("action", "getdata");
		var username:String;
		for (username in usernames) req.setParameter("usernames[]", username);
		req.setParameter("begining", Std.string(begining));
		req.setParameter("end", Std.string(end));
		if (resolution != null) req.setParameter("resolution", Std.string(resolution));
		req.onReply = f;
		req.send();
		return req;
	}
	
	static public function putData(usernames:List<String>, data:List<DataRecord>, trust:Int, f:List<Dynamic>->Void) {
		var req = new BackendRequest();
		req.setParameter("action", "putdata");
		var username:String;
		for (username in usernames) req.setParameter("usernames[]", username);
		req.setParameter("data", Serializer.run(data));
		req.setParameter("trust", Std.string(trust));
		req.onReply = f;
		req.send();
		return req;
	}
	
	static public function getStatistic(f:List<Dynamic>->Void) {
		//TODO: Implement the getStatistic funtion properly
		var req = new BackendRequest();
		req.setParameter("action", "getstat");
		req.onReply = f;
		req.send();
		return req;
	}
	
	
	static public function readSetting(f:List<Dynamic>->Void) {
		//TODO: Implement the readSetting funtion properly
		var req = new BackendRequest();
		req.setParameter("action", "readsetting");
		req.onReply = f;
		req.send();
		return req;
	}
	
	override public function onStatus(s:Int) {
		trace(s);
	}
	
	public function responce(responce:String) {
		if (responce == null) {
			if (onReply != null) onReply(new List());
			return;
		}
		var data:Array<String> = responce.split("/n");
		var out:List<Dynamic> = new List();
		try {
			for (item in data) {
				out.push(Unserializer.run(item));
			}
		} catch (e:Fatal) {
			switch (e.type) {
				case UNAUTHORISED(spec): out.push(e);
				default: trace(e.message);
			}
		}
		if (onReply != null) onReply(out);
	}
	
	function error(msg:String) {
		trace(msg);
		//trace(responseHeaders);
	}
	
	public function send() {
		request(false);
	}
}