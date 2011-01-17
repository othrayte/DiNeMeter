package webmonitormaster;

/**
 * ...
 * @author othrayte
 */

class TimeUtils {

	public static function getStandardBegining(connection:Connection):Date {
		var index:Int = connection.monthStartTime;
		var now:Date = Date.now();
		var out:Int = new Date(now.getFullYear(), now.getMonth()-1, 1, 0, 0, 0).getTime() + index;
		if (out < now.getTime()) {
			out = new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0).getTime() + index;
		}
		return DateTools.make({seconds:out}); 
	}
	
	public static function getStandardEnd(connection:Connection):Date {
		throw "Not implemented";
		return new Date(); 
	}
	
}