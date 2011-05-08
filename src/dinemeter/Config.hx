package dinemeter;
import haxe.Serializer;
import haxe.Unserializer;
#if php
import php.io.File;
#elseif cpp
import cpp.io.File;
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
 * @author Adrian Cowan (Othrayte)
 */

class Config {
	private var _:Hash<Dynamic>;
	private var path:String;
	
	public function new(?path:String) {
		_ = new Hash();
		if (path != null) readFile(path);
	}
	
	public function readFile(path:String) {
		this.path = path;
		var raw = File.getContent(path);
		var lines = raw.split("\n");
		for (line in lines) {
			var components:Array<String> = StringTools.trim(line).split("=");
			var name:String = components.shift();
			var type:String = components.shift();
			var piece:String = components.join("=");
			var data:Dynamic;
			switch (type.toLowerCase()) {
				case "int", "integer", "hex", "hexadecimal": data = Std.parseInt(piece);
				case "float", "number": data = Std.parseFloat(piece);
				case "string", "text": data = piece;
				case "other", "serialised": data = Unserializer.run(piece);
				default: data = piece;
			}
			_.set(name, data);
		}
	}
	
	public function get(name:String):Dynamic {
		if (_.exists(name)) return _.get(name);
		return null;
	}
	
	public function set(name:String, value:Dynamic) {
		_.set(name, value);
	}
	
	public function writeFile(?path:String) {
		if (path==null) path = this.path;
		var f = File.write(path, false);
		for (item in _.keys()) {
			var val = _.get(item);
			if (Std.is(val, Int)) {
				f.writeString(item + "=int=" + val + "\n");
			} else if (Std.is(val, Float)) {
				f.writeString(item + "=float=" + val + "\n");
			} else if (Std.is(val, String)) {
				f.writeString(item + "=string=" + val + "\n");
			} else {
				f.writeString(item + "=other=" + Serializer.run(val) + "\n");
			}
		}
		f.close();
	}
}