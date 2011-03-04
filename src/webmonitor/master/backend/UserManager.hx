package webmonitor.master.backend;

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

class UserManager extends php.db.Manager<StoredUser> {
    public function new() {
        super(StoredUser);
    }
	
	
    
	public function byName(name: String, ?connection:StoredConnection) {
		if (connection != null) return object(select("`name` = " + quote(name) + " and connectionId = " + connection.id), true); 
        return object(select("name = " + name), true);
    }
}