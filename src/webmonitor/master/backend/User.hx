package webmonitor.master.backend;

import haxe.BaseCode;
import haxe.io.BytesInput;
import haxe.Md5;
import php.db.Object;
import php.Web;

import webmonitor.crypto.Tea;
import webmonitor.Fatal;

using webmonitor.master.backend.DataRecord;

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

class User extends Object {
	static var TABLE_IDS = ["id"];
	
	public var id:Int;
	public var name:String;
	public var password:String;
	public var downQuota:Int;
	public var upQuota:Int;
	public var connectionId:Int;
	public var sessionId:String;
	public var sessionIp:String;
	public var sessionTimeout:Int;
	

	public function new() 	{
		super();
	}
	
	public static var manager = new UserManager();
	
	#if php
	public function can(priveledgeName:String):Bool {
		var out:Bool = (Priveledge.manager.getPriveledge(priveledgeName, this) == null) ? false : true;
		return out;
	}
	
	public function allow(priveledgeName:String) {
		Priveledge.manager.set(priveledgeName, this);
	}
	
	public function prevent(priveledgeName:String) {
		Priveledge.manager.remove(priveledgeName, this);
	}
	
	public function checkCredentials(credentials:String, ?session:Bool = false):Bool {
		var key:String;
		if (session) {
			if (sessionIp != Web.getClientIP()) throw new Fatal(UNAUTHORISED(SESSION_IP_WRONG));
			if (sessionTimeout > Date.now().getTime()) throw new Fatal(UNAUTHORISED(SESSION_TIMEOUT));
			key = sessionId;			
		} else {
			key = password;
		}
		
		var decrypted:String = Tea.decrypt(credentials, key);
		var sections:Array<String> = decrypted.split(":");
		if (sections.length != 2) throw new Fatal(UNAUTHORISED(INVALID_CRED_STAGE_1));
		if (Md5.encode(sections[0]).substr(0,32) != sections[1].substr(0,32)) throw new Fatal(UNAUTHORISED(INVALID_CRED_STAGE_2));
		if (session) {
			sessionTimeout = Std.int(DateTools.delta(Date.now(), 60*60).getTime()); // Session times out in one hour;
			update();
		}
		return true;
	}
	
	public function getData(begining:Int, end:Int, ?resolution:Int = 0):List<DataRecord> {
		var samples:List<DataRecord> = DataRecord.manager.getData(begining, end, this);
		if (resolution == 0) {
			return samples;
		}
		return samples.refactor(begining, end, resolution);
	}
	#end
}