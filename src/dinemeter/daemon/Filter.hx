package dinemeter.daemon;

/**
 *  This file is part of DiNeMeterDaemon.
 *
 *  DiNeMeterDaemon is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  any later version.
 *
 *  DiNeMeterDaemon is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with DiNeMeterDaemon.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * @author Adrian Cowan (Othrayte)
 */

class Filter {
	public var min:Int;
	public var max:Int;
	public var child:Filter;
	public var next:Filter;
	
	public function new() {
		
	}
	
	public function toString():String {
		return "{ " + min + ", " + max + ", " + child + ", " + next + "}";
	}
}