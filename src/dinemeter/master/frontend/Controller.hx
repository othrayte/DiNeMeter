#if js
package dinemeter.master.frontend;
import dinemeter.client.BackendRequest;
import dinemeter.Connection;
import dinemeter.User;
import js.LocalStorage;
import dinemeter.Priveledge;

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
	public static var currentConnectionId:Int;
	public static var currentConnectionName:String;
	public static var currentUserId:Int;
	public static var currentUserName:String;
	
	public static function showHideBtns() {
		var usernames:List<String> = new List();
		usernames.push(currentUserName);
		new JQuery(".MenuItem").hide();
		new JQuery("#logoutBtn").show();
		BackendRequest.readPriveledges(usernames, function(data:Array<Dynamic>) {
			var a:Hash<Hash<Priveledge>> = data[0];
			trace(a);
			var currentPriv:Hash<Priveledge> = a.get(currentUserName);
			if (currentPriv.exists('getdata:*') || currentPriv.exists('getdata:' + currentUserId)) {
				new JQuery("#myDataBtn").show();
			} else {
				new JQuery("#myDataBtn").hide();
			}
			if (currentPriv.exists('getdata:*')) {
				new JQuery("#connectionDataBtn").show();
			} else {
				new JQuery("#connectionDataBtn").hide();
			}
			if (currentPriv.exists('getdata:*')) {
				new JQuery("#auditingBtn").show();
			} else {
				new JQuery("#auditingBtn").hide();
			}
			if (currentPriv.exists('changesetting:*')) {
				new JQuery("#users_PriveledgesBtn").show();
			} else {
				new JQuery("#users_PriveledgesBtn").hide();
			}
			if (currentPriv.exists('changesetting:*')) {
				new JQuery("#connectionBtn").show();
			} else {
				new JQuery("#connectionBtn").hide();
			}
		});
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
	
	static function show(section:String) {
		new JQuery(".Content").css( { display: "none" } );
		new JQuery("#"+section).css( { display: "block" } );
		if (Crumb.root.name != section) {
			Crumb.root = new Crumb(section);
			Crumb.rootPrint();
		}
	}
	
	public static function showMyData() {
		show('myData');
	}
	
	public static function showConnectionData() {
		show('connectionData');
	}
	
	public static function showAuditing() {
		show('auditing');
	}
	
	public static function showUsers_Priveledges() {
		show('users_Priveledges');
	}
	
	public static function showConnection() {
		show('connection');
	}
	
	public static function logout() {
		show('logout');
		LoginBox.logout();
	}
	
	public static function readCrumbs() {
		Crumb.root = Crumb.decode();
		if (Crumb.root == null) {
			Crumb.root = new Crumb("myData");
			showMyData();
			return;
		}
		switch(Crumb.root.name) {
			case "myData": showMyData();
			case "connectionData": showConnectionData();
			case "auditing": showAuditing();
			case "users_Priveledges": showUsers_Priveledges();
			case "connection": showConnection();			
			default: showMyData();
		}
	}
	
}
#end