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

class GuiContainer {
	private var _a:Array<GuiContainer>;
	public var id:String;
	private var cssWritten:Bool;
	static private var css:String = "";
	static private var _mId:Int = 0;
	
	private function new(?id:String) {
		_a = new Array();
		if (id == null) {
			this.id = "WMM_" + ++_mId;
		} else {
			this.id = id;
		}
		cssWritten = false;
	}
	
	public function put(?pos:Int, container:GuiContainer) {
		if (pos == null) {
			_a.push(container);
		}
		_a[pos] = container;
	}
	
	public function get(?pos:Int) {
		if (pos == null) {
			return _a[0];
		}
		return _a[pos];
	}
	
	public function write() {
		return "";
	}
	
	public function writeCss() {
		if (!cssWritten) {
			cssWritten = true;
			return "";
		}
		return "";
	}
	
	#if js
	public function init() {
		for (item in _a) {
			item.init();
		}
	}
	#end
}