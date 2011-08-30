#if js
package dinemeter.master.frontend;
import dinemeter.client.BackendRequest;
import dinemeter.Connection;
import dinemeter.DataRecord;
import dinemeter.User;
import js.Dom;
import js.Lib;

import js.LocalStorage;

import dinemeter.Priveledge;

using dinemeter.DataMath;

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
	
	static var usageWorm:UsageWorm;
	static var usageGraph:UsageGraph;
	static var userSP:UserSettings_Privs;
	
	private static var pauser:Void->Void;
	
	public static function init() {
		usageWorm = new UsageWorm("usageWorm");
		usageGraph = new UsageGraph("dataHistory");
		userSP = new UserSettings_Privs("users", "addUserBtn", {name: "userName", downQuota: "userDownQuota", upQuota: "userUpQuota", password: "userPassword", save: "saveUser", delete: "deleteUser", downloadDaemon: "downloadDaemon"});
		
		Controller.showHideBtns();
		Controller.readCrumbs();
		Controller.enableBtns();
	}
	
	public static function showHideBtns() {
		new JQuery(".MenuItem").hide();
		new JQuery("#logoutBtn").show();
		BackendRequest.whenLoggedIn(function() {
			var usernames:List<String> = new List();
			usernames.push(currentUserName);
			BackendRequest.readPriveledges(usernames, function(data:Array<Dynamic>) {
				var a:Hash<Hash<Priveledge>> = data[0];
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
	
	static function show(section:String, ?pauser:Void->Void) {
		new JQuery(".Content").fadeOut(200);//.css( { display: "none" } );
		new JQuery("#"+section).delay(200).fadeIn(100);//.css( { display: "block" } );
		if (Crumb.root.name != section) {
			Crumb.root = new Crumb(section);
			Crumb.rootPrint();
		}
		if (Controller.pauser != null) Controller.pauser();
		Controller.pauser = pauser;
	}
	
	public static function showMyData() {
		initMyData();
		show('myData', pauseMyData);
		execMyData();
	}
	
	public static function showConnectionData() {
		initConnectionData();
		show('connectionData', pauseConnectionData);
		execConnectionData();
	}
	
	public static function showAuditing() {
		initAuditing();
		show('auditing', pauseAuditing);
		execAuditing();
	}
	
	public static function showUsers_Priveledges() {
		initUsers_Priveledges();
		show('users_Priveledges', pauseUsers_Priveledges);
		execUsers_Priveledges();
	}
	
	public static function showConnection() {
		initConnection();
		show('connection', pauseConnection);
		execConnection();
	}
	
	public static function logout() {
		show('logout');
		LoginBox.logout();
	}
	
	public static function initMyData() {
        usageGraph.setup([currentUserName]);
	}
	
	public static function initConnectionData() {
		
	}
	
	public static function initAuditing() {
		
	}
	
	public static function initUsers_Priveledges() {
		
	}
	
	public static function initConnection() {
		
	}
	
	static function working(name:String, ?go:Bool) {
		if (go == true) new JQuery("#" + name + " .Working").addClass("Running").fadeIn();
		if (go == false) new JQuery("#" + name + " .Working").removeClass("Running").fadeOut();
		if (new JQuery("#"+name+" .Working").data("working") == null) new JQuery(".Working").data("working", 0);
		var i = new JQuery("#"+name+" .Working").data("working");
		new JQuery("#"+name+" .Working").removeClass("Working" + i++);
		if (i > 4) i = 1;
		new JQuery("#"+name+" .Working").data("working", i).addClass("Working" + i);
		new JQuery("#" + name + " .Running").animate( { width: 8, height: 8, top: -4, right: -4 }, 100);
		new JQuery("#"+name+" .Running").animate( { width: 10, height: 10, top: -5, right: -5}, 100, callback(working, name, null));
	}
	
	public static function execMyData() {
		working("stats", true);
		working("worm", true);
		working("data", true);
		BackendRequest.whenLoggedIn(function() {
			var usernames:List<String> = new List();
			usernames.push(currentUserName);
			BackendRequest.readSetting(["downMetered", "upMetered", "downQuota", "upQuota"], function (responce) {
				var settings:Hash<Dynamic> = responce[0].get(currentUserId);
				BackendRequest.getData(usernames, function (responce) {
					var data:Hash<DataList<DataRecord>> = responce[0];
					BackendRequest.getDefaultRange(function (responce) {
						var start:Int = responce[0];
						var end:Int = responce[1];
						var monthEnd:Int = responce[2];
						var daysLeft:Float = (monthEnd - end) / (60 * 60 * 24);
						
						var totals:DataRecord = DataRecord.total(data.get(currentUserName), start, end);
						
						var downMetered:Bool = settings.get("downMetered");
						var upMetered:Bool = settings.get("upMetered");
						var downQuota:Int = settings.get("downQuota");
						var upQuota:Int = settings.get("upQuota");
						
						// Update stats
						if (downMetered) {
							var unusedDown:Int = downQuota - totals.down;
							if (unusedDown < 0) unusedDown = 0;
							new JQuery("#unusedDown").text(unusedDown.format());
							new JQuery("#downLeftPDay").text((unusedDown / daysLeft).format());
						} else {
							new JQuery("#unusedDown").text("∞");
							new JQuery("#downLeftPDay").text("∞");							
						}
						
						if (upMetered) {
							var unusedUp:Int = upQuota - totals.up;
							if (unusedUp < 0) unusedUp = 0;
							new JQuery("#unusedUp").text(unusedUp.format());
							new JQuery("#upLeftPDay").text((unusedUp / daysLeft).format());
						} else {
							new JQuery("#unusedUp").text("∞");
							new JQuery("#upLeftPDay").text("∞");							
						}
						
						new JQuery("#down").text(totals.down.format());
						new JQuery("#up").text(totals.up.format());
						new JQuery("#uDown").text(totals.uDown.format());
						new JQuery("#uUp").text(totals.uUp.format());
						working("stats", false);
						
						// Update usage worm
						
						usageWorm.display(data.get(currentUserName), start, end, monthEnd, downQuota, upQuota, downMetered, upMetered);
						working("worm", false);
                        
                        // Update data history graph
						usageGraph.display(data, start, end, monthEnd);
                        working("data", false);
					});
					
				});
			});
		});
	}
	
	public static function execConnectionData() {
		
	}
	
	public static function execAuditing() {
		
	}
	
	public static function execUsers_Priveledges() {
		userSP.updateList();
	}
	
	public static function execConnection() {
		
	}
	
	public static function pauseMyData() {
		
	}
	
	public static function pauseConnectionData() {
		
	}
	
	public static function pauseAuditing() {
		
	}
	
	public static function pauseUsers_Priveledges() {
		
	}
	
	public static function pauseConnection() {
		
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