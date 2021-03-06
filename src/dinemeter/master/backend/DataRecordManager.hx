package dinemeter.master.backend;

import dinemeter.Util;

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

class DataRecordManager extends php.db.Manager<StoredDataRecord> {
    public function new() {
        super(StoredDataRecord);
    }
	
	public function getData(begining:Int, end:Int, ?user:IUser, ?archiveState:Int = -1):DataList<StoredDataRecord> {
        var query = "`end` >= " + begining + " AND `start` <= " + end;
        if (user != null) query += " AND `userId` = " + user.id;
        if (archiveState >= 0) query += " AND `archived` = " + archiveState;
        var responce = objects(select(query), true);
		return new DataList(StoredDataRecord, responce);
	}
	
	public function getDataForArc(begining:Int, end:Int, ?user:IUser, ?nextArchiveState:Int = -1):DataList<StoredDataRecord> {
        var query = "`end` >= " + begining + " AND `start` <= " + end;
        if (user != null) query += " AND `userId` = " + user.id;
        if (nextArchiveState >= 0) query += " AND `archived` <= " + nextArchiveState;
        var responce = objects(select(query), true);
		return new DataList(StoredDataRecord, responce);
	}
}