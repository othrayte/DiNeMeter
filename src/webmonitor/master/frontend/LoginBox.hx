package webmonitor.master.frontend;
#if js
import JQuery;
import webmonitor.Fatal;
import js.LocalStorage;
//import webmonitormastergui.MasterGui;
#end
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

class LoginBox extends GuiContainer {
	var username:String;
	var password:String;
	
	public function new(?id:String) {
		super(id);
	}
	
	#if js
	
	override public function init() {
		var self = this;
		if (LocalStorage.supported()) {
			if (LocalStorage.getItem('username') == null || LocalStorage.getItem('sessionId') == null) {
				new JQuery("#" + id).delay(300).fadeIn(600);
				new JQuery("#" + id + "-submit").click(function() {self.login();});
			} else {
				MasterGui.username = LocalStorage.getItem('username');
				MasterGui.sessionId = LocalStorage.getItem('sessionId');
			}
		}
	}
	
	
	public function login() {
		username = new JQuery("#" + id + "-username").val();
		password = new JQuery("#" + id + "-password").val();
		MasterGui.backendLogin(username, password, responce);
	}
	
	public function responce(data:List<Dynamic>) {
		if (Std.is(data.first(), String)) {
			MasterGui.username = username;
			MasterGui.sessionId = data.first();
			trace(LocalStorage.supported());
			if (LocalStorage.supported()) {
				LocalStorage.setItem('username', MasterGui.username);
				LocalStorage.setItem('sessionId', MasterGui.sessionId);
			}
			loggedIn();
		} else {
			if (Std.is(data.first(), Fatal)) {
				var e:Fatal = cast data.first();
				switch (e.type) {
					case UNAUTHORISED(spec):
						switch (spec) {
							case NO_USER(username): js.Lib.alert("Username is wrong");
							case INVALID_CRED, INVALID_CRED_STAGE_1, INVALID_CRED_STAGE_2: js.Lib.alert("Password is wrong");
							default: throw "Unexpected error";
						}
					default:
				}
			} else {
				
			}
		}
		
	}
	
	public function loggedIn() {
		new JQuery("#" + id + " > *").fadeOut("slow");
		new JQuery("#" + id).delay(600).animate( { width: "80px", borderRadius: "100px" }, 400).animate( { width: "6px", height: "6px", marginTop: "117px"}, 200).fadeOut(200);
		
	}
	
	#end
	
	#if php
	override public function write() {
		var out:String;
		out =  "<div class='LoginBox' id='" + id + "'>\n";
		out += "	<span class='LoginBoxField'>Username</span><input class='LoginBoxField' id='" + id + "-username' type='text'>\n";
		out += "	<span class='LoginBoxField'>Password</span><input class='LoginBoxField' id='" + id + "-password' type='password'>\n";
		out += "	<input class='LoginBoxButton' id='" + id + "-submit' type='submit' value='Login'>\n";
		out += "</div>";
		return out;
	}
	
	override public function writeCss() {
		if (!cssWritten) {
			cssWritten = true;
			var out:String;
			out =  ".LoginBox {\n";
			out += "	display: none;\n";
			out += "	margin: 80px auto;\n";
			out += "	height: 75px;\n";
			out += "	width: 220px;\n";
			out += "	background-color: #94ACE4;\n";
			out += "	border: solid 2px #3862A7;\n";
			out += "	border-radius: 10px;\n";
			out += "	padding: 10px;\n";
			out += "}\n";
			out += "span.LoginBoxField {\n";
			out += "	float: left;\n";
			out += "	height: 18px;\n";
			out += "	width: 70px;\n";
			out += "	margin: 5px 0px 5px 3px;\n";
			out += "	padding: 1px 2px 1px 6px;\n";
			out += "	text-align: right;\n";
			out += "	font-size: 15px;\n";
			out += "	color: #223D68;\n";
			out += "	font-family: sans-serif;\n";
			out += "	background-color: #B6C8E7;\n";
			out += "	border: solid 2px #3862A7;\n";
			out += "	border-top-left-radius: 12px;\n";
			out += "	border-bottom-left-radius: 12px;\n";	
			out += "}\n";
			out += "input.LoginBoxField{\n";
			out += "	float: left;\n";
			out += "	width: 122px;\n";
			out += "	height: 18px;\n";
			out += "	margin: 5px 3px 5px 0px;\n";
			out += "	padding: 1px 6px 1px 2px;\n";
			out += "	font-size: 15px;\n";
			out += "	text-align: left;\n";	
			out += "	background-color: #D9E2F2;\n";
			out += "	border: solid 2px #3862A7;\n";
			out += "	border-left: 0px;\n";
			out += "	border-top-right-radius: 12px;\n";
			out += "	border-bottom-right-radius: 12px;\n";
			out += "}\n";
			out += ".LoginBoxButton {\n";
			out += "	height: 24px;\n";
			out += "	margin: 5px 15px 5px auto;\n";
			out += "	float: right;\n";
			out += "	padding: 1px 12px 1px 12px;\n";
			out += "	text-align: right;\n";
			out += "	font-size: 15px;\n";
			out += "	color: #223D68;\n";
			out += "	font-family: sans-serif;\n";
			out += "	background-color: #B6C8E7;\n";
			out += "	border: solid 2px #3862A7;\n";
			out += "	border-radius: 12px;\n";
			out += "}\n";
			out += ".LoginBoxButton:hover {\n";
			out += "	background-color: #D9E2F2;\n";
			out += "}\n";
			return out;
		}
		return "";
	}
	#end
	
}