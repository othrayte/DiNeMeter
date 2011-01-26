package webmonitormaster;
import php.db.Object;

/**
 * ...
 * @author othrayte
 */

class DataRecord extends Object {
	static var TABLE_IDS = ["id"];
	
	public var id:Int;
	
	public var trust:Int;
	
	public var archived:Bool;
	
	public var down:Int;
	public var up:Int;
	public var uDown:Int;
	public var uUp:Int;
	
	public var start:Int;
	public var end:Int;
	

	public function new() 	{
		super();
	}
	
	public static var manager = new DataRecordManager();
}