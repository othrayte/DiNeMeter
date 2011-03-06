package dinemeter;

#if php
import php.io.File;
import php.io.FileOutput;
import php.Lib;
import php.io.FileInput;
#end

import haxe.io.Eof;

import dinemeter.Fatal;

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

class Util {
	static var messages:List<String> = new List();
	public static inline function log(m:String) {
		#if debug
			messages.add(m);
		#end
	}
	
	#if php
	public static function splurt() {
		for (message in messages) {
			Lib.println(message+"<br />");
		}
	}
	
	public static function record(?e:Fatal) {
		var logFile:FileOutput = File.append("log.txt", false);
		if (e != null) {
			logFile.writeString("[" + DateTools.format(Date.now(), "%H:%M:%S") + "] (" + e.code + ") " + e.message + "\n");
		} else {
			logFile.writeString("[" + DateTools.format(Date.now(), "%H:%M:%S") + "] Debug record \n");
		}
		
		for (message in messages) {
			logFile.writeString("[" + DateTools.format(Date.now(), "%H:%M:%S") + "] " + message + "\n");
		}
		messages.clear();
	}
	#end
}