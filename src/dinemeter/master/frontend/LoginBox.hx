#if js
package dinemeter.master.frontend;

import JQuery;
import dinemeter.client.BackendRequest;
import dinemeter.Fatal;
import js.LocalStorage;
//import dinemetermastergui.MasterGui;
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

class LoginBox {
	static var username:String;
	static var password:String;
	static var loggedIn:Bool = false;
	
	static var onLogin:Void->Void;
	
	public static function needLogin(f:Void->Void) {
		if (loggedIn) {
			f();
		} else {
			if (LocalStorage.supported()) {
				if (LocalStorage.getItem('username') == null || LocalStorage.getItem('sessionId') == null) {
					onLogin = f;
					show();
				} else {
					BackendRequest.useSessionId(LocalStorage.getItem('sessionId'), LocalStorage.getItem('username'));
					loggedIn = true;
					f();
				}
			} else {
				LoginBox.onLogin = f;
				show();
			}
		}
	}
	
	public static function logout() {
		LocalStorage.removeItem('sessionId');
		BackendRequest.useSessionId("");
		password = "";
		loggedIn = false;
	}
	
	public static function show() {
		if (LocalStorage.getItem('username') != null) new JQuery("#username").val(LocalStorage.getItem('username'));
		new JQuery("#username #password").css({color: "black"});
		new JQuery("#loginSubmit").bind('click', login);
		new JQuery("#login").bind('keydown', function(event) {
			new JQuery("#username, #password").css({color: "black"});
			if (event.keyCode == '13') {
				login();
			}
		});
		new JQuery("#loginOverlay").fadeIn(100);
		new JQuery("#login").delay(300).fadeIn(600);
	}
	
	public static function login() {
		username = new JQuery("#username").val();
		password = new JQuery("#password").val();
		BackendRequest.initSession(password, username, responce);
	}
	
	public static function responce(data:List<Dynamic>) {
		if (Std.is(data.first(), String)) {
			BackendRequest.useSessionId(data.first(), username);
			LocalStorage.setItem('username', username);
			LocalStorage.setItem('sessionId', data.first());
			loggedIn = true;
			hide();
			if (onLogin != null) onLogin();
		} else {
			if (Std.is(data.first(), Fatal)) {
				var e:Fatal = cast data.first();
				switch (e.type) {
					case UNAUTHORISED(spec):
						switch (spec) {
							case NO_USER(username): new JQuery("#username").css({color: "#EE3333"});
							case INVALID_CRED, INVALID_CRED_STAGE_1, INVALID_CRED_STAGE_2:  new JQuery("#password").css({color: "#EE3333"});
							default: throw "Unexpected error";
						}
					default:
				}
			} else {
				
			}
		}
		
	}
	
	public static function hide() {
		new JQuery("#loginSubmit").unbind('click');
		new JQuery("#login > *").fadeOut("slow");
		new JQuery("#login").delay(600).animate( { width: "80px", borderRadius: "100px" }, 400).animate( { width: "6px", height: "6px", marginTop: "117px" }, 200).fadeOut(200, function() {
			new JQuery("#loginOverlay").fadeOut("fast");
		});
	}
	
	/*
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
	*/
	
}
#end