package dinemeter.master.backend;

import dinemeter.User;
import haxe.BaseCode;
import haxe.io.BytesInput;
import haxe.Md5;
import php.db.Object;
import php.Web;

import dinemeter.crypto.Tea;
import dinemeter.Fatal;
import dinemeter.DataRecord;
import dinemeter.IUser;

using dinemeter.DataRecord;

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

class StoredUser extends Object, implements IUser{
	static var TABLE_NAME = "user";
	static var TABLE_IDS = ["id"];
	
	public var id:Int;
	public var name:String;
	public var password:String;
	public var downQuota:Float;
	public var upQuota:Float;
	public var connectionId:Int;
	public var sessionId:String;
	public var sessionIp:String;
	public var sessionTimeout:Int;
	

	public function new() {
		super();
	}
	
	public function staticCopy() {
		var out:IUser = new User();
		out.id = id;
		out.name = name;
		out.password = "*****";
		out.downQuota = downQuota;
		out.upQuota = upQuota;
		out.connectionId = connectionId;
		return out;
	}
	
	public static var manager = new UserManager();
	
	public function can(priveledgeName:String, ?target:String):Bool {
		if (target == null) target = "*";
		var out:Bool = (StoredPriveledge.manager.getPriveledge(priveledgeName, target, this) == null) ? false : true;
        if (out == false && target != "*") out = (StoredPriveledge.manager.getPriveledge(priveledgeName, "*", this) == null) ? false : true;
		return out;
	}
	
	public function allow(priveledgeName:String) {
		StoredPriveledge.manager.set(priveledgeName, this);
	}
	
	public function prevent(priveledgeName:String) {
		StoredPriveledge.manager.remove(priveledgeName, this);
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
		var rawSamples:List<StoredDataRecord> = StoredDataRecord.manager.getData(begining, end, this);
		var samples:List<DataRecord> = new List();
		for (record in rawSamples) {
			samples.add(record.strip());
		}
		if (resolution == 0) {
			return samples;
		}
		return DataRecord.refactor(samples, begining, end, resolution);
	}
}