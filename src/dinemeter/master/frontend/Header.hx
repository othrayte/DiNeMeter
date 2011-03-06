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

class Header extends GuiContainer {

	public function new() {
		super();
	}
	
	override public function write() {
		var out:String;
		out =  "<div class='Header' id='" + id + "'>\n";
		out +=  "	DiNeMeterMaster\n";
		out += "</div>";
		return out;
	}
	
	override public function writeCss() {
		if (!cssWritten) {
			cssWritten = true;
			var out:String;
			out =  ".Header {\n";
			out += "	width: 100%;\n";
			out += "	height: 60px;\n";
			out += "	background-color: #94ACE4;\n";
			out += "	border-bottom: solid 2px #3862A7;\n";
			out += "	text-align: center;\n";
			out += "	font-size: 50px;\n";
			out += "	color: #3862A7;\n";
			out += "	font-family: sans-serif;\n";
			out += "	font-weight: bold;\n";			
			out += "}\n";
			return out;
		}
		return "";
	}
}