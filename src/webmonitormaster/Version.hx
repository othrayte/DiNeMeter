package webmonitormaster;
import php.db.Object;

/**
 * ...
 * @author othrayte
 */

class Version extends Object {	
	public var version:Int;
	
	public static var manager = new php.db.Manager<Version>(Version);
}