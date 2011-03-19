package dinemeter.master.backend;
import dinemeter.Fatal;
import php.db.Object;
import dinemeter.IConnection;

import php.db.Object;
/**
 *  This file is part of DiNeMeterMaster.
 *
 *  DiNeMeterMaster is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Affero General Public License as
 *  published by the Free Software Foundation, either version 3 of the
 *  License, or any later version.
 *
 *  DiNeMeterMaster is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Affero General Public License for more details.
 *
 *  You should have received a copy of the GNU Affero General Public License
 *  along with DiNeMeterMaster.  If not, see <http://www.gnu.org/licenses/>.
 *
 * @author Adrian Cowan (othrayte)
 */

class StoredConnection extends Object, implements IConnection {
	static var TABLE_NAME = "connection";
	static var TABLE_IDS = ["id"];
	
	public var id:Int;
	public var name:String;
	public var downQuota:Int;
	public var upQuota:Int;
	public var downMetered:Bool;
	public var upMetered:Bool;
	
	public var monthStartTime:Int; // Seconds from start of month to new data month
	
	public static var manager = new ConnectionManager();
	
	public function getUser(?name:String, ?id:Int):StoredUser {
		if (name!=null) {
			return StoredUser.manager.byName(name, this);
		} else if (id != null) {
			return StoredUser.manager.get(id);
		} else {
			throw new Fatal(SERVER_ERROR(LOGIC_BOMB));
		}
		
	}
	
}