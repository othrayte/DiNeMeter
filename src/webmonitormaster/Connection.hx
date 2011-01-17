package webmonitormaster;
import php.db.Object;

/**
 * ...
 * @author othrayte
 */

class Connection extends Object {
	static var TABLE_IDS = ["id"];
	
	public var id:Int;
	public var name:String;
	
	
	public static var manager = new ConnectionManager();
	
	public function getUser(name):User {
		return User.manager.byName(name, this);
	}
	
}