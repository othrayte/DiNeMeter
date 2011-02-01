package webmonitormaster;
import haxe.Md5;
import haxe.SHA1;
import php.db.Object;

/**
 * ...
 * @author othrayte
 */

class User extends Object {
	static var TABLE_IDS = ["id"];
	
	public var id:Int;
	public var name:String;
	public var password:String;
	public var downQuota:Int;
	public var upQuota:Int;
	public var connectionId:Int;
	

	public function new() 	{
		super();
	}
	
	public static var manager = new UserManager();
	
	public function can(priveledgeName:String):Bool {
		var out:Bool = (Priveledge.manager.getPriveledge(priveledgeName, this) == null) ? false : true;
		return out;
	}
	
	public function allow(priveledgeName:String) {
		Priveledge.manager.set(priveledgeName, this);
	}
	
	public function prevent(priveledgeName:String) {
		Priveledge.manager.remove(priveledgeName, this);
	}
	
	public function checkCredentials(credentials:String):Bool {
		var decrypted:String = Tea.decrypt(credentials, password);
		var sections:Array<String> = decrypted.split(":");
		if (sections.length != 2) throw new Fatal(401, "Unauthorised - invalid credentials, stage 1");
		if (Md5.encode(sections[0]).substr(0,32) != sections[1].substr(0,32)) throw new Fatal(401, "Unauthorised - invalid credentials, stage 2");
		return true;
	}
	
	public function getData(begining:Date, end:Date, resolution:Int):List<DataRecord> {
		var samples:List<DataRecord> = DataRecord.manager.getData(Math.floor(begining.getTime()/1000), Math.floor(end.getTime()/1000), this);
		var sort:Array<IntHash<DataRecord>> = new Array();
		
		if (resolution == 0) {
			trace(samples);
			return samples;
		}
		for (sample in samples) {
			if (sort[sample.trust] == null) sort[sample.trust] = new IntHash();
			var sT:Int = Math.floor(sample.start / resolution) * resolution; // Start time
			var cT:Int = sT; // Current time
			var lT:Int = Math.floor(sample.end / resolution) * resolution; // Last time
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
				var block:DataRecord;
				if (sort[sample.trust].exists(cT)) {
					block = sort[sample.trust].get(cT);
				} else {
					block = new DataRecord();
					block.start = cT;
					block.end = cT + resolution;
					block.trust = sample.trust;
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
				sort[sample.trust].set(cT, block);
				cT += resolution;
				cP = 1;
			}
		}
		var out:List<DataRecord> = new List();
		for (trustLevel in sort) {
			if (trustLevel == null) continue;
			for (block in trustLevel) {
				out.push(block);
			}
		}
		trace(out);
		return out;
	}
}