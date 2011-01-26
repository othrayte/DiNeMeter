package webmonitormaster;
import haxe.Md5;
import haxe.SHA1;
import php.db.Object;

/**
 * ...
 * @author othrayte
 */

class User extends Object {
	static var TABLE_IDS = ["id"];
	
	public var id:Int;
	public var name:String;
	public var password:String;
	public var downQuota:Int;
	public var upQuota:Int;
	public var connectionId:Int;
	

	public function new() 	{
		super();
	}
	
	public static var manager = new UserManager();
	
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
	
	public function checkCredentials(credentials:String):Bool {
		var decrypted:String = Tea.decrypt(credentials, password);
		var sections:Array<String> = decrypted.split(":");
		trace(sections);
		if (sections.length != 2) throw new Fatal(401, "Unauthorised - invalid credentials, stage 1");
		if (Md5.encode(sections[0]).substr(0,32) != sections[1].substr(0,32)) throw new Fatal(401, "Unauthorised - invalid credentials, stage 2");
		return true;
	}
	
	public function getData(begining:Date, end:Date, resolution:Int, downloads:Bool, uploads:Bool, unmeteredDownloads:Bool, unmeteredUploads:Bool):List<DataRecord> {
		var sample = DataRecord.manager.getData(Math.floor(begining.getTime()/1000), Math.floor(end.getTime()/1000), downloads, uploads, unmeteredDownloads, unmeteredUploads);
		return new List();
	}
}