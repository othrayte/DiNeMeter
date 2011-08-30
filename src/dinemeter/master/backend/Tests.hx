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
        for (i in 0 ... 1) {
            var dr = new DataRecord();
            dr.userId = 0;
            dr.trust = 3;
            dr.down = 100;
            dr.up = 50;
            dr.uDown = 2;
            dr.start = start;
            start += 100;
            dr.end = start;
            dl.add(dr);
        }
        try {
            trace(dl);
            trace(dl.refactor(0,4*100+50,50));
            trace(dl.refactor(0, 4 * 100 + 50, 123));
        }
        catch (e:Dynamic) {
            trace(e);
        }
    }
    
    static function msg(message:String) {
        trace(message);
    }
}