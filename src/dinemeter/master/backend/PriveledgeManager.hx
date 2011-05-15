package dinemeter.master.backend;
import dinemeter.IPriveledge;
import dinemeter.IUser;

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

class PriveledgeManager extends php.db.Manager<StoredPriveledge> {
    public function new() {
        super(StoredPriveledge);
    }
	
	public function getAllFor(user:IUser) {
		return objects(select("`userId` = " + user.id), true);
	}
	
	public function getPriveledge(priveledgeName:String, target:String, user:IUser) {
		return object(select("`name` = " + quote(priveledgeName) + " AND `target` = " + quote(target) + " AND `userId` = " + user.id), true);
	}
	
	public function set(priveledgeName:String, ?target:String="*", user:IUser) {
		if (object(select("`name` = " + quote(priveledgeName) + " AND `target` = " + quote(target) + " AND `userId` = " + user.id), true) == null) {
			var p = new StoredPriveledge();
			p.name = priveledgeName;
            p.target = target;
			p.userId = user.id;
			p.insert();
		}
	}
	
	public function remove(priveledgeName:String, ?target:String, user:StoredUser) {
        if (target == null) {
            var pA = objects(select("`name` = " + quote(priveledgeName) + " AND `userId` = " + user.id), true);
            for (p in pA) if (p != null) p.delete();
        } else {
            var p = object(select("`name` = " + quote(priveledgeName) + " AND `target` = " + quote(target) + " AND `userId` = " + user.id), true);
            if (p != null) p.delete();
        }
	}
	
}