package webmonitormaster;
import php.db.Object;

/**
 *  This file is part of WebMonitorMaster.
 *
 *  WebMonitorMaster is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  any later version.
 *
 *  WebMonitorMaster is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with WebMonitorMaster.  If not, see <http://www.gnu.org/licenses/>.
 *
 * @author Adrian Cowan (othrayte)
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