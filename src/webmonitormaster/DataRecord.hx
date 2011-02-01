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
	
	public var userId:Int;

	public function new() 	{
		super();
	}
	
	public static var manager = new DataRecordManager();
	
	override public function toString() {
		return "DR: "+down+":"+up+":"+uDown+":"+uUp;
	}
	
	function hxSerialize(s: haxe.Serializer) {
        s.serialize(id);
        s.serialize(trust);
        s.serialize(archived);
        s.serialize(down);
        s.serialize(up);
        s.serialize(uDown);
        s.serialize(uUp);
        s.serialize(start);
        s.serialize(end);
        s.serialize(userId);
	}
	
    function hxUnserialize(s: haxe.Unserializer) {
		id = s.unserialize();
        trust = s.unserialize();
        archived = s.unserialize();
        down = s.unserialize();
        up = s.unserialize();
        uDown = s.unserialize();
        uUp = s.unserialize();
        start = s.unserialize();
        end = s.unserialize();
        userId = s.unserialize();       
    }
}