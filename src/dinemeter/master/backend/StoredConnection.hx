package dinemeter.master.backend;
import php.db.Object;

import dinemeter.Fatal;
import dinemeter.IConnection;
import dinemeter.Util;

using dinemeter.DataRecord;

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
	
    public function refactorArchive() {
        Util.log("Refactoring archive started");
        var now:Int = Math.floor(Date.now().getTime()/1000);
        var archL1Size:Int = 20*60;
        var archL1Start:Int = now-15*60;
        var archL2Size:Int = 2*60*60;
        var archL2Start:Int = now - 2 * 24 * 60 * 60;
        // Find any that need to be refactored to level 1
        try {
            php.db.Manager.cnx.startTransaction();
            var oldData:DataList<StoredDataRecord> = StoredDataRecord.manager.getDataForArc(0, archL1Start, 1);
            if (oldData.length > 0) Util.log("Found " + oldData.length + " data records to archive to level 1");
            Util.log(oldData.toString());
            var newData:DataList<StoredDataRecord> = oldData.refactor(0, archL1Start+archL1Size, archL1Size);
            Util.log(oldData.toString());
            Util.log(newData.toString());
            for (record in oldData) record.delete();
            for (record in newData) {
                if (record.down == 0 && record.up == 0 && record.uDown == 0 && record.uUp == 0) continue;
                record.archived = 1;
                record.insert();
            }
            php.db.Manager.cnx.commit();
            Util.important("Refactoring archive level 1 compleated");
        } catch (e:Dynamic){
            Util.important("Refactoring archive level 1 aborted");
            php.db.Manager.cnx.rollback();
            throw e;
        }
        // Find any that need to be refactored to level 2
        try {
            php.db.Manager.cnx.startTransaction();
            var oldData:DataList<StoredDataRecord> = StoredDataRecord.manager.getDataForArc(0, archL2Start, 2);
            if (oldData.length > 0) Util.log("Found " + oldData.length + " data records to archive to level 2");
            var newData:DataList<StoredDataRecord> = oldData.refactor(0, archL2Start+archL2Size, archL2Size);
            for (record in oldData) record.delete();
            for (record in newData) {
                if (record.down == 0 && record.up == 0 && record.uDown == 0 && record.uUp == 0) continue;
                record.archived = 2;
                record.insert();
            }
            php.db.Manager.cnx.commit();
            Util.important("Refactoring archive level 2 compleated");
        } catch (e:Dynamic){
            Util.important("Refactoring archive level 2 aborted");
            php.db.Manager.cnx.rollback();
            throw e;
        }
        Util.log("Refactoring archive done");
    }
}