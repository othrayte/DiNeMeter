package dinemeter.master.backend;
import php.db.Object;
import dinemeter.IPriveledge;

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

class StoredPriveledge extends Object, implements IPriveledge{
	static var TABLE_NAME = "priveledge";
	static var TABLE_IDS = ["id"];
	
	public var id:Int;
	public var name:String;
	public var target:String;
	public var userId:Int;
	
	public static var manager = new PriveledgeManager();
	
	public function new() {
		super();
	}
}