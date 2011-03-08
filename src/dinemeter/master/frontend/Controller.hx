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

class Controller {
	
	public static function showHideBtns() {
		//TODO: Change this function to check priveledges, when they can be checked
		/*new JQuery("#myData").show();
		new JQuery("#myData").show();
		new JQuery("#myData").show();
		new JQuery("#myData").show();*/
	}
	
	public static function enableBtns() {
		new JQuery("#myDataBtn").bind('click', showMyData);
		new JQuery("#connectionDataBtn").bind('click', showConnectionData);
		new JQuery("#auditingBtn").bind('click', showAuditing);
		new JQuery("#users_PriveledgesBtn").bind('click', showUsers_Priveledges);
		new JQuery("#connectionBtn").bind('click', showConnection);
		new JQuery("#logoutBtn").bind('click', logout);
	}
	
	public static function showMyData() {
		new JQuery(".Content").css( { display: "none" } );
		new JQuery("#myData").css( { display: "block" } );
	}
	
	public static function showConnectionData() {
		new JQuery(".Content").css( { display: "none" } );
		new JQuery("#connectionData").css( { display: "block" } );
	}
	
	public static function showAuditing() {
		new JQuery(".Content").css( { display: "none" } );
		new JQuery("#auditing").css( { display: "block" } );
	}
	
	public static function showUsers_Priveledges() {
		new JQuery(".Content").css( { display: "none" } );
		new JQuery("#users_Priveledges").css( { display: "block" } );
	}
	
	public static function showConnection() {
		new JQuery(".Content").css( { display: "none" } );
		new JQuery("#connection").css( { display: "block" } );
	}
	
	public static function logout() {
		new JQuery(".Content").css( { display: "none" } );
		new JQuery("#logout").css( { display: "block" } );
		LoginBox.logout();
	}
	
}
#end