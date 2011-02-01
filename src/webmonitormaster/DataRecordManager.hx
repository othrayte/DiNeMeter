package webmonitormaster;

/**
 * ...
 * @author othrayte
 */

class DataRecordManager extends php.db.Manager<DataRecord> {
    public function new() {
        super(DataRecord);
    }
	
	public function getData(begining:Int, end:Int, user:User):List<DataRecord> {
		return objects(select("start >= " + begining + " AND end <= " + end + " AND userId = " + user.id), true);		
	}
}