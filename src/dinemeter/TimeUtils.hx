package dinemeter;
import dinemeter.Connection;

import dinemeter.Util;

using dinemeter.Util;

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

class TimeUtils {

	public static function getStandardBegining(connection:IConnection):Int {
		var index:Int = connection.monthStartTime;
		var now:Date = Date.now();
		var out:Int = Math.floor(new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0).getTime()/1000) + index;
		if (out > now.getTime()/1000) {
			out = Math.floor(new Date(now.getFullYear(), now.getMonth()-1, 1, 0, 0, 0).getTime()/1000) + index;
		}
		return out; 
	}
	
	public static function getStandardEnd(connection:IConnection):Int {
		return Math.floor(Date.now().getTime()/1000);
	}
	
	public static function getMonthEnd(connection:IConnection):Int {
		var index:Int = connection.monthStartTime;
		var now:Date = Date.now();
		var out:Int = Math.floor(new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0).getTime()/1000) + index;
		if (out < now.getTime()/1000) {
			out = Math.floor(new Date(now.getFullYear(), now.getMonth()+1, 1, 0, 0, 0).getTime()/1000) + index;
		}
		return out; 
	}	
}