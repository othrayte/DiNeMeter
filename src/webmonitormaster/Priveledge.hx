package webmonitormaster;

/**
 * ...
 * @author othrayte
 */

class Priveledge {
	static var TABLE_IDS = ["id"];
	
	public var id:Int;
	public var name:String;
	
	public static var manager = new UserManager();
	
	public function new() {
		super();
	}
	
}