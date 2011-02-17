package webmonitor.master.frontend;

/**
 *  This file is part of WebMonitorMaster.
 *
 *  WebMonitorMaster is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Affero General Public License as
 *  published by the Free Software Foundation, either version 3 of the
 *  License, or any later version.
 *
 *  WebMonitorMaster is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Affero General Public License for more details.
 *
 *  You should have received a copy of the GNU Affero General Public License
 *  along with WebMonitorMaster.  If not, see <http://www.gnu.org/licenses/>.
 *
 * @author othrayte
 */

class HorizontalSplit extends GuiContainer {

	public function new() {
		super();
	}
	
	override public function write() {
		var out:String;
		out =  "<div class='HorizontalSplit' id='" + id + "'>\n";
		var out2:String = "";
		for (container in _a) {
			out2 += container.write();
		}
		out +=  "	"+StringTools.replace(out2, "\n", "\n	")+"\n";
		out += "</div>";
		return out;
	}
	
	override public function writeCss() {
		if (!cssWritten) {
			cssWritten = true;
			var out:String;
			out =  ".HorizontalSplit {\n";
			out += "	width: 100%;\n";
			out += "	height: 100%;\n";
			out += "}\n";
			for (container in _a) {
				out += container.writeCss();
			}
			return out;
		}
		return "";
	}
}