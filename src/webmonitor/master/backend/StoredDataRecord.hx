package webmonitor.master.backend;
import php.db.Object;
import webmonitor.DataRecord;

/**
 *  This file is part of WebMonitorMaster.
 *
 *  WebMonitorMaster is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Affero General Public License as
 *  published by the Free Software Foundation, either version 3 of the
 *  License, or any later version.
 *
 *  WebMonitorMaster is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Affero General Public License for more details.
 *
 *  You should have received a copy of the GNU Affero General Public License
 *  along with WebMonitorMaster.  If not, see <http://www.gnu.org/licenses/>.
 *
 * @author Adrian Cowan (othrayte)
 */

class StoredDataRecord extends Object, implements DataRecord {
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