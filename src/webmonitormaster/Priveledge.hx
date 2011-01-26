package webmonitormaster;
import php.db.Object;

/**
 * ...
 * @author othrayte
 */

class Priveledge extends Object {
	static var TABLE_IDS = ["id"];
	
	public var id:Int;
	public var name:String;
	public var userId:Int;
	
	public static var manager = new PriveledgeManager();
	
	public function new() {
		super();
	}
	
}