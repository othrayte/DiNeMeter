package dinemeter;

/**
 *  This file is part of DiNeMeter.
 *
 *  DiNeMeter is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  any later version.
 *
 *  DiNeMeter is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with DiNeMeter.  If not, see <http://www.gnu.org/licenses/>.
 *
 * @author Adrian Cowan (othrayte)
 */

class DataMath {

	public static function format(d:Float) {
		var count:Int=0;
		while (d > 1024) {
			count++;
			d /= 1024;
		}
		if (d != 0) {
			var t = Math.pow(10, 4 - Math.ceil(Math.log(d)/Math.log(10)));
			d = Math.round(d * t) / t;
		}
		return Std.string(d) + ["B", "kB", "MB", "GB", "TB", "PB"][count];
	}
}