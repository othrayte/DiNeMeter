package dinemeter.master.frontend;

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

class RootFill extends GuiContainer {
	
	public function new() {
		super();
	}
	
	override public function write() {
		var out:String;
		out =  "<div class='RootFill' id='" + id + "'>\n";
		var out2:String;
		out2 = _a[0].write();
		out +=  "	"+StringTools.replace(out2, "\n", "\n	")+"\n";
		out += "</div>";
		return out;
	}
	
	override public function writeCss() {
		if (!cssWritten) {
			cssWritten = true;
			var out:String;
			out =  ".RootFill {\n";
			out += "	position: absolute;\n";
			out += "	top: 0;\n";
			out += "	left: 0;\n";
			out += "	width: 100%;\n";
			out += "	height: 100%;\n";
			out += "}\n";
			out += _a[0].writeCss();
			return out;
		}
		return "";
	}
}