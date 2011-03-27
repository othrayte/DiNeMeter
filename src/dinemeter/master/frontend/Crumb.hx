package dinemeter.master.frontend;
import haxe.Serializer;

/**
 *  This file is part of DiNeMeterMaster.
 *
 *  DiNeMeterMaster is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Affero General Public License as
 *  published by the Free Software Foundation, either version 3 of the
 *  License, or any later version.
 *
 *  DiNeMeterMaster is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Affero General Public License for more details.
 *
 *  You should have received a copy of the GNU Affero General Public License
 *  along with DiNeMeterMaster.  If not, see <http://www.gnu.org/licenses/>.
 *
 * @author othrayte
 */

class Crumb {
	public static var root:Crumb;
	public var name(default, null):String;
	var data:String;
	var child:Crumb;
	
	public function new(name:String, ?data:Dynamic) {
		this.name = name;
		this.data = (data == null) ? null : Serializer.run(data);
		if (root == null) root = this;
	}
	
	public function print() {
		return name + ((data == null) ? "" : ("|" + data)) + ((child == null) ? "" : (">" + child.print()));
	}
	
	public static function rootPrint() {
		js.Lib.window.location.hash = root.print();
	}
	
	public function changeData(?data:Dynamic) {
		this.data = (data == null) ? null : Serializer.run(data);
		rootPrint();
	}
	
	public function setChild(?crumb:Crumb) {
		child = crumb;
		rootPrint();
	}
	
	public static function decode() {
		var s1:Array<String> = js.Lib.window.location.hash.substr(1).split(">");
		var out:Crumb = null;
		for (s2 in s1) {
			var s3:Array<String>;
			s3 = s2.split("|");
			var t:Crumb = new Crumb(s3[0], s3[1]);
			if (out == null) {
				out = t;
			} else {
				out.setChild(t);
			}
		}
		return out;
	}
}