package webmonitormaster;

/**
 * ...
 * @author othrayte
 */

class DataRecord extends Object {
	static var TABLE_IDS = ["id"];
	
	public var id:Int;
	
	public var start:Int;
	public var end:Int;
	
	public function new() 	{
		super();
	}
	
	public static var manager = new dataManager();
	
}