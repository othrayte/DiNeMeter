package webmonitor.master.backend;

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

class DataRecordManager extends php.db.Manager<DataRecord> {
    public function new() {
        super(DataRecord);
    }
	
	public function getData(begining:Int, end:Int, user:User):List<DataRecord> {
		return objects(select("`end` >= " + begining + " AND `start` <= " + end + " AND `userId` = " + user.id), true);		
	}
}