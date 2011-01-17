package webmonitormaster;
import crypt.Tea;
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
		return (manager.get(priveledgeName, this) == null) ? false : true;
	}
	
	public function allow(priveledgeName:String) {
		manager.set(priveledgeName, this);
	}
	
	public function prevent(priveledgeName:String) {
		manager.remove(priveledgeName, this);
	}
	
	public function checkCredentials(credentials:String):Bool {
		var cypher:crypt.Tea = new Tea(SHA1.encode(user.password));
		var decrypted:String = cypher.decryptBlock(credentials);
		
		
		return false; // Need to check credentials
	}
	
	public function getData(begining:Int, end:Int, resolution:Int, downloads:Bool, uploads:Bool, unmeteredDownloads:Bool, unmeteredUploads:Bool) {
		var sample = DataRecord.manager.getData(begining, end, downloads, uploads, unmeteredDownloads, unmeteredUploads);
	}
}