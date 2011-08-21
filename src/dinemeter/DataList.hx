package dinemeter;

/**
 * ...
 * @author Adrian Cowan (Othrayte)
 */

class DataList < T:(IDataRecord) > extends List<T> {
    var cl:Class<T>;
    public function new(cl:Class<T>, ?primitive:List<T>=null) {
        this.cl = cl;
        super();
        if (primitive!=null) {
            untyped { this.h = primitive.h; };
            untyped { this.q = primitive.q; };
            untyped { this.length = primitive.length; };
        }
    }
    
    public function refactor(start:Int, end:Int, resolution:Int):DataList<T> {
		var sort:Array<Array<IntHash<T>>> = new Array();
		for (sample in this) {
			if (sort[sample.trust] == null) sort[sample.trust] = new Array();
			if (sort[sample.trust][sample.userId] == null) sort[sample.trust][sample.userId] = new IntHash();
			var sT:Int = Math.floor((sample.start - start) / resolution) * resolution + start; // Start time
			var cT:Int = sT; // Current time
			var lT:Int = Math.floor((sample.end - start) / resolution) * resolution + start; // Last time
			var dT:Float = (sample.end - sample.start) / resolution; // delta time
			var cP:Float = (cT + resolution - sample.start) / resolution; // Current percent
			var dD:Float = sample.down / dT; // delta down per block
			var tD:Int = 0; // Total down already in blocks
			var dU:Float = sample.up / dT; // delta up per block
			var tU:Int = 0; // Total up already in blocks
			var dUD:Float = sample.uDown / dT; // delta unmetered down per block
			var tUD:Int = 0; // Total unmetered down already in blocks
			var dUU:Float = sample.uUp / dT; // delta unmetered up per block
			var tUU:Int = 0; // Total unmetered up already in blocks
			while (cT <= lT) {
				var block:T;
				if (sort[sample.trust][sample.userId].exists(cT)) {
					block = sort[sample.trust][sample.userId].get(cT);
				} else {
					block = Type.createInstance(cl, []);
					block.start = cT;
					block.end = cT + resolution;
					block.trust = sample.trust;
					block.userId = sample.userId;
				}
				if (cT == lT) {
					block.down += sample.down - tD;
					block.up += sample.up - tU;
					block.uDown += sample.uDown - tUD;
					block.uUp += sample.uUp - tUU;
				} else {
					block.down += tD += Math.floor(dD * cP);
					block.up += tU += Math.floor(dU * cP);
					block.uDown += tUD += Math.floor(dUD * cP);
					block.uUp += tUU += Math.floor(dUU * cP);
				}
				sort[sample.trust][sample.userId].set(cT, block);
				cT += resolution;
				cP = 1;
			}
		}
		var out:DataList<T> = new DataList(cl);
		for (trustLevel in sort) {
			if (trustLevel == null) continue;
			for (user in trustLevel) {
				if (user == null) continue;
				for (block in user)
					if (block.end <= end && block.start >= start) out.push(block);
			}
		}
		return out;
	}
}