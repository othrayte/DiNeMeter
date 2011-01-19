package webmonitormaster;
//import crypt.Tea;
import haxe.SHA1;
import php.db.Object;

/**
 * ...
 * @author othrayte
 */

class User extends Object {
	static var TABLE_IDS = ["id"];
	
	public var id:Int;

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
		//var cypher:crypt.Tea = new Tea(SHA1.encode(user.password));
		//var decrypted:String = cypher.decryptBlock(credentials);
		
		
		return false; // Need to check credentials
	}
	
	public function getData(begining:Date, end:Date, resolution:Int, downloads:Bool, uploads:Bool, unmeteredDownloads:Bool, unmeteredUploads:Bool):List<DataRecord> {
		var sample = DataRecord.manager.getData(Math.floor(begining.getTime()/1000), Math.floor(end.getTime()/1000), downloads, uploads, unmeteredDownloads, unmeteredUploads);
		return new List();
	}
}