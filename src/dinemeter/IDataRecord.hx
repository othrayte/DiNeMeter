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

interface IDataRecord {	
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
}