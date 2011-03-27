package dinemeter.master.frontend;

import dinemeter.client.BackendRequest;
import js.Lib;
import js.Dom;

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

class UserSettings_Privs {
	var users:List<{name:String, id:Int}>;
	var id:String;
	var addId:String;
	var selectedUser:{ name:String, id:Int };
	var settingIds: { name:String, downQuota:String, upQuota:String, password:String, delete:String };
	
	public function new(id:String, addId:String, settingIds:{name:String, downQuota:String, upQuota:String, password:String, delete:String}) {
		this.id = id;
		this.addId = addId;
		this.settingIds = settingIds;
		this.selectedUser = { name:null, id:0 };
		new JQuery("#" + addId).bind('click', addNewUser);
		new JQuery("#" + settingIds.delete).bind('click', deleteSelectedUser);
	}
	
	public function updateList() {	
		BackendRequest.listUsers(cb1);
	}
	
	function cb1(responce:Array<Dynamic>) {
		this.users = responce[0];
		new JQuery(".User").remove();
		for (user in users) {
			var nameDiv:HtmlDom = Lib.document.createElement("div");
			nameDiv.className = "User Btn";
			nameDiv.id = id+":" + user.id;
			nameDiv.innerHTML = user.name;
			nameDiv.onclick = callback(cb2, user.name, user.id);
			new JQuery("#"+id).append(nameDiv);
		}
	}
	
	function cb2(name:String, id:Int, e:Event) {
		selectUser(name, id);
	}
	
	public function addNewUser() {
		BackendRequest.whenLoggedIn(cb3);
	}
	
	function cb3() {
		BackendRequest.addUser(Controller.currentConnectionId, "NewUser", "password", 0, 0, cb4);
	}
	
	function cb4(responce:Array<Dynamic>) {
		updateList();		
	}
	
	public function selectUser(name:String, id:Int) {
		selectedUser = { name: name, id: id };
		updateSettings();
		updatePriveledges();
	}
	
	public function updateSettings() {
		if (selectedUser.name != null) {
			new JQuery("#" + settingIds.name).val(selectedUser.name);
			BackendRequest.readSetting([selectedUser.id], ["downQuota", "upQuota"], cb5);
		} else {
			new JQuery("#" + settingIds.name).val("");
			new JQuery("#" + settingIds.downQuota).val("");
			new JQuery("#" + settingIds.upQuota).val("");
			new JQuery("#" + settingIds.password).val("");
		}
	}
	
	function cb5(responce:Array<Dynamic>) {
		var settings:Hash<Dynamic> = responce[0].get(selectedUser.id);
		new JQuery("#" + settingIds.downQuota).val(DataMath.format(settings.get("downQuota")));
		new JQuery("#" + settingIds.upQuota).val(DataMath.format(settings.get("upQuota")));
	}
	
	function deleteSelectedUser() {
		if (selectedUser.name != null) {
			BackendRequest.removeUser(selectedUser.id, null);
			selectedUser = { name:null, id:0 };
			updateList();
			updateSettings();
		}
	}
	
	public function updatePriveledges() {
		
	}
}