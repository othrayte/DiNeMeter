package webmonitormaster;

/**
 * ...
 * @author othrayte
 */

class TimeUtils {

	public static function getStandardBegining(connection:Connection):Int {
		var index:Int = connection.monthStartTime;
		var now:Date = Date.now();
		var out:Int = Math.floor(new Date(now.getFullYear(), now.getMonth()-1, 1, 0, 0, 0).getTime()/1000) + index;
		if (out < now.getTime()) {
			out = Math.floor(new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0).getTime()/1000) + index;
		}
		return out; 
	}
	
	public static function getStandardEnd(connection:Connection):Int {
		return Math.floor(Date.now().getTime()/1000);
	}
	
}