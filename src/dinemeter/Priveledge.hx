package dinemeter;
#if php
import dinemeter.master.backend.StoredPriveledge;
#end

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

class Priveledge implements IPriveledge {
	public var name:String;
	public var target:String;
	public var userId:Int;
	
	public function new(name:String, target:String, userId:Int) {
		this.name = name;
		this.target = target;
		this.userId = userId;
	}
	#if php
	public static function fromStoredPriveledge(priv:StoredPriveledge) {
		return new Priveledge(priv.name, priv.target, priv.userId);
	}
	#end
}