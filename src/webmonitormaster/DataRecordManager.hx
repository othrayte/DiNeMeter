package webmonitormaster;

/**
 * ...
 * @author othrayte
 */

class DataRecordManager extends php.db.Manager<DataRecord> {
    public function new() {
        super(User);
    }
	
	public function getData(begining:Int, end:Int, downloads:Bool, uploads:Bool , unmeteredDownloads:Bool, unmeteredUploads:Bool) {
		
		
	}
}