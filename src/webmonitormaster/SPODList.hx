package webmonitormaster;
import php.db.Object;

/**
 * ...
 * @author othrayte
 */

class SPODList<T> extends List<T>, implements Object {
	var __cache__ : Object;
	var __noupdate__ : Bool;
	
	
	
	
	public static var manager = new neko.db.Manager<SPODList>(SPODList);
	
	public function new() {
		__init_object()	;
	}

	private function __init_object() {
		__noupdate__ = false;
		var rl : Array<Dynamic>;
		try {
			rl = untyped manager.cls.RELATIONS();
		} catch(e : Dynamic) { return; }
		for(r in rl)
			untyped manager.initRelation(this, r);
	}
	
	public function insert() {
		manager.doInsert(this);
	}

	public function update() {
		if( __noupdate__ ) throw "Cannot update not locked object";
		manager.doUpdate(this);
	}

	public function sync() {
		manager.doSync(this);
	}

	public function delete() {
		manager.doDelete(this);
	}

	public function toString() {
		return manager.objectToString(this);
	}
	
	
	
	
	
	
}