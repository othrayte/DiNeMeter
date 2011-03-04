package webmonitormastergui;

import webmonitormastergui.LoginBox;
import webmonitormastergui.RootFill;
import webmonitormastergui.HorizontalSplit;
import webmonitormastergui.Header;
#if js
import js.LocalStorage;
#end
/**
 *  This file is part of WebMonitorMaster.
 *
 *  WebMonitorMaster is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  any later version.
 *
 *  WebMonitorMaster is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with WebMonitorMaster.  If not, see <http://www.gnu.org/licenses/>.
 *
 * @author othrayte
 */

class Main {
	static public function main() {
		new JQuery(function () {
			var loginBox:LoginBox = cast MasterGui.root.get().get(1);
			if (LocalStorage.supported()) {
				if (LocalStorage.getItem('username') == null || LocalStorage.getItem('sessionId') == null) {
					loginBox.show();
					loginBox.onLogin = loggedIn;
				} else {
					MasterGui.username = LocalStorage.getItem('username');
					MasterGui.sessionId = LocalStorage.getItem('sessionId');
					
					showRequest();
				}
			} else {
				loginBox.show();
			}
		});
	}
	
	static function loggedIn() {
		var loginBox:LoginBox = cast MasterGui.root.get().get(1);
		loginBox.hide(showRequest);
	}
	
	static function showRequest() {
		MasterGui.root.get().remove(1);
		MasterGui.root.get().pull("main", 1);
	}
}