package webmonitor;

/**
 *  This file is part of WebMonitor.
 *
 *  WebMonitor is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Affero General Public License as
 *  published by the Free Software Foundation, either version 3 of the
 *  License, or any later version.
 *
 *  WebMonitor is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Affero General Public License for more details.
 *
 *  You should have received a copy of the GNU Affero General Public License
 *  along with WebMonitor.  If not, see <http://www.gnu.org/licenses/>.
 *
 * @author Adrian Cowan (othrayte)
 */

class DataRecord {
	public var id:Int;
	
	public var trust:Int;
	
	public var archived:Bool;
	
	public var down:Int;
	public var up:Int;
	public var uDown:Int;
	public var uUp:Int;
	
	public var start:Int;
	public var end:Int;
	
	public var userId:Int;

	public function new() 	{

	}
	
	public function toString() {
		return "DR: "+down+":"+up+":"+uDown+":"+uUp;
	}
	static public function refactor(current:List<DataRecord>, start:Int, end:Int, resolution:Int) {
		var sort:Array<IntHash<DataRecord>> = new Array();
		for (sample in current) {
			if (sort[sample.trust] == null) sort[sample.trust] = new IntHash();
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
				if (block.end <= end && block.start >= start) out.push(block);
			}
		}
		return out;
	}
	
	static public function total(current:List<DataRecord>, start:Int, end:Int, ?trustLevel:Null<Int> = null) {
		var sort:Array<DataRecord> = new Array();
		for (sample in current) {
			if (trustLevel != null && trustLevel != sample.trust) continue;
			if (sample.start >= start && sample.end <= end) {
				if (sort[sample.trust] == null) {
					sort[sample.trust] = new DataRecord();
					sort[sample.trust].start = start;
					sort[sample.trust].end = end;
					sort[sample.trust].trust = sample.trust;
				}
				sort[sample.trust].down += sample.down;
				sort[sample.trust].up += sample.up;
				sort[sample.trust].uDown += sample.uDown;
				sort[sample.trust].uUp += sample.uUp;
			} else if (sample.end > start && sample.end <= end) {
				if (sort[sample.trust] == null) {
					sort[sample.trust] = new DataRecord();
					sort[sample.trust].start = start;
					sort[sample.trust].end = end;
					sort[sample.trust].trust = sample.trust;
				}
				var p:Float = (sample.end-sample.start)/(sample.end-start);
				sort[sample.trust].down += Math.round(sample.down/p);
				sort[sample.trust].up += Math.round(sample.up/p);
				sort[sample.trust].uDown += Math.round(sample.uDown/p);
				sort[sample.trust].uUp += Math.round(sample.uUp/p);
			} else if (sample.start >= start && sample.start < end) {
				if (sort[sample.trust] == null) {
					sort[sample.trust] = new DataRecord();
					sort[sample.trust].start = start;
					sort[sample.trust].end = end;
					sort[sample.trust].trust = sample.trust;
				}
				var p:Float = (sample.end-sample.start)/(end-sample.start);
				sort[sample.trust].down += Math.round(sample.down/p);
				sort[sample.trust].up += Math.round(sample.up/p);
				sort[sample.trust].uDown += Math.round(sample.uDown/p);
				sort[sample.trust].uUp += Math.round(sample.uUp/p);				
			}
		}
		if (trustLevel == null) {
			for (out in sort) {
				if (out != null) return out;
			}
		} else {
			return sort[trustLevel];
		}
		return new DataRecord();
	}
}