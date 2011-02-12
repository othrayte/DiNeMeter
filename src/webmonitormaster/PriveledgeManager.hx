package webmonitormaster;

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

class PriveledgeManager extends php.db.Manager<Priveledge> {
    public function new() {
        super(Priveledge);
    }
	
	public function getPriveledge(priveledgeName:String, user:User) {
		return object(select("`name` = " + quote(priveledgeName) + " AND `userId` = " + user.id), true);
	}
	
	public function set(priveledgeName:String, user:User) {
		if (object(select("`name` = " + quote(priveledgeName) + " AND `userId` = " + user.id), true) == null) {
			var p = new Priveledge();
			p.name = priveledgeName;
			p.userId = user.id;
			p.insert();
		}
	}
	
	public function remove(priveledgeName:String, user:User) {
		var p = object(select("`name` = " + quote(priveledgeName) + " AND `userId` = " + user.id), true);
		if (p != null) p.delete();		
	}
	
}