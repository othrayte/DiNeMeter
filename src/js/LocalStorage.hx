package js;

/**
 * This negledgable class is not elegable for any copywrite or copyleft. 
 * @author othrayte
 */

class LocalStorage {
	#if js
	public static function setItem(key:String, value:String):Bool {
		return untyped __js__("localStorage.setItem(key, value)");
	}
	
	public static function getItem(key:String):String {
		return untyped __js__("localStorage.getItem(key)");
	}
	
	public static function removeItem(key:String):String {
		return untyped __js__("localStorage.removeItem(key)");
	}
	
	public static function clear():Void {
		untyped __js__("localStorage.clear()");
	}
	
	public static function supported():Bool {
		untyped __js__("try {
		return 'localStorage' in window && window['localStorage'] !== null;
	} catch (e) {
		return false;
	}");
		return false;
	}
	#end	
}