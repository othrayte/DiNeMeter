<<<<<<< HEAD:src/webmonitormastergui/GuiContainer.hx
package webmonitormastergui;
import webmonitormaster.Fatal;
=======
package webmonitor.master.frontend;
>>>>>>> 61490c4db0950a0926109eb21a49c0d8085f3401:src/webmonitor/master/frontend/GuiContainer.hx

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
	static public var _mId:Int = 0;
	
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
		if (pos == null) return _a[0];
		return _a[pos];
	}
	
	public function remove(?pos:Int) {
		if (pos == null) pos = 0;
		#if js
			_a[pos].id;
			new JQuery("#" + _a[pos].id).remove();
		#end
		_a.splice(pos, 1);
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
	public function pull(type:String, pos:Int) {
		MasterGui.backend( { block: type, idStart: GuiContainer._mId }, callback(pullR, pos));
	}
	private function pullR(pos:Int, res:List<Dynamic>) {
		if (Std.is(res, Fatal)) {
			
			
		} else {
			var css = res.pop();
			var text = res.pop();
			var obj = res.pop();
			GuiContainer._mId = res.pop();
			
			if (_a[pos] != null) remove(pos);
			new JQuery("head:first").append(css);
			if (pos > 0) {
				new JQuery("#" + _a[pos - 1].id).after(text);
			} else {
				new JQuery("#" + id).prepend(text);
			}
			_a[pos] = obj;
			_a[pos].init();
		}
	}
	
	public function init() {
		for (item in _a) {
			item.init();
		}
	}
	#end
}