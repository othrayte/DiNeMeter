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
        for (i in 0 ... 6) {
            var dr = new DataRecord();
            dr.trust = 3;
            dr.down = 100;
            dr.up = 50;
            dr.uDown = 2;
            dr.start = start;
            start += 100;
            dr.end = start;
            dl.push(dr);
        }
        trace(dl);
        trace(dl.refactor(0,6*100+150,123));
        trace(dl.refactor(0,6*100+50,1000));
    }
    
    static function msg(message:String) {
        trace(message);
    }
}