package dinemeter;

/**
 *  This file is part of DiNeMeter.
 *
 *  DiNeMeter is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Affero General Public License as
 *  published by the Free Software Foundation, either version 3 of the
 *  License, or any later version.
 *
 *  DiNeMeter is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Affero General Public License for more details.
 *
 *  You should have received a copy of the GNU Affero General Public License
 *  along with DiNeMeter.  If not, see <http://www.gnu.org/licenses/>.
 *
 * @author Adrian Cowan (othrayte)
 */

class DataRecord implements IDataRecord {
	public var id:Int;
	
	public var trust:Int;
	
	public var archived:Int;
	
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
		return "DR: "+down+"D:"+up+"U:"+uDown+"UD:"+uUp+"UU<"+start+"-"+end+">";
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