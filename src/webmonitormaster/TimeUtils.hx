package webmonitormaster;

/**
 * ...
 * @author othrayte
 */

class TimeUtils {

	public static function getStandardBegining(connection:Connection):Date {
		var index:Int = connection.monthStartTime*1000;
		var now:Date = Date.now();
		var out:Int = Math.floor(new Date(now.getFullYear(), now.getMonth()-1, 1, 0, 0, 0).getTime()) + index;
		if (out < now.getTime()) {
			out = Math.floor(new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0).getTime()) + index;
		}
		return Date.fromTime(out); 
	}
	
	public static function getStandardEnd(connection:Connection):Date {
		return Date.now();
	}
	
}