#if js
package dinemeter.master.frontend;

import dinemeter.client.BackendRequest;
import js.LocalStorage;
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

class Main {
	static public function main() {
		BackendRequest.url = "./";
		BackendRequest.requestCred = LoginBox.needLogin;
		new JQuery(function () {
			Controller.showHideBtns();
			Controller.readCrumbs();
			Controller.enableBtns();
			
			new JQuery("#body").fadeIn();
		});
	}
}
#end