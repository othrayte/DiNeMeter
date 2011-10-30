package dinemeter.master.backend;
import dinemeter.DataList;
import dinemeter.DataRecord;

/**
 * ...
 * @author Adrian Cowan (Othrayte)
 */

class Tests {
    static public function refactor1() {
        var dl = new DataList(DataRecord);
        var start = 50;
        for (i in 0 ... 5) {
            var dr = new DataRecord();
            dr.userId = 0;
            dr.trust = 3;
            dr.down = 100;
            dr.up = 50;
            dr.uDown = 2;
            dr.start = start;
            //start += 25;
            dr.end = start+25;
            dl.add(dr);
        }
        try {
            trace(dl);
            trace(dl.refactor(0,4*100+50,50));
            //trace(dl.refactor(0, 4 * 100 + 50, 123));
            //trace(dl.refactor(0,4*100+50,150));
        }
        catch (e:Dynamic) {
            trace(e);
        }
    }
	
    static public function refactor2() {
        var dl = new DataList(StoredDataRecord);
        var dr = new StoredDataRecord();
		dr.archived = 0;
		dr.userId = 5;
		dr.trust = 3;
		dr.down = 161287;
		dr.up = 3452976;
		dr.uDown = 0;
		dr.uUp = 0;
		dr.start = 1319938655;
		dr.end = 1319938685;
		dl.add(dr);
        var dr = new StoredDataRecord();
		dr.archived = 1;
		dr.userId = 5;
		dr.trust = 3;
		dr.down = 3370;
		dr.up = 4380;
		dr.uDown = 0;
		dr.uUp = 0;
		dr.start = 1319938660;
		dr.end = 1319938690;
		dl.add(dr);
        try {
            trace(dl);
            trace(dl.refactor(0,Math.floor(Date.now().getTime()/1000)-15*60,20*60));
        }
        catch (e:Dynamic) {
            trace(e);
        }
    }
    
    static function msg(message:String) {
        trace(message);
    }
}