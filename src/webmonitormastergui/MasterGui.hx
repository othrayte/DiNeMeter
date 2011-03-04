package webmonitormastergui;

import haxe.FastList;
import webmonitormaster.Master;
import webmonitormaster.Fatal;

#if php
import php.Lib;
import haxe.Serializer;
#end


#if js
import haxe.Md5;
import haxe.Unserializer;
import js.LocalStorage;
import webmonitormaster.Tea;
import JQuery;
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
 * @author Adrian Cowan (othrayte)
 */

class MasterGui {	
	static public var root:GuiContainer;
	static public var username:String;
	static public var sessionId:String;
	
	#if php
	static public function embed(params) {
		if (!params.exists('idStart')) throw new Fatal(INVALID_REQUEST(MISSING_ID_START));
		GuiContainer._mId = Std.parseInt(params.get('idStart'));
		switch (params.get('container')) {
			case "main":
				root = new Header();
			default : throw new Fatal(INVALID_REQUEST(INVALID_CONTAINER(params.get('container'))));
		}
		Master.queueData(root.writeCss());
		Master.queueData(root.write());
		Master.queueData(root);
		Master.queueData(GuiContainer._mId);
	}
	
	static public function embedStart() {
		root = new RootFill();
		root.put(new HorizontalSplit());
		root.get().put(new Header());
		root.get().put(new LoginBox());
		embedPage(root);
	}
	
	static private function embedPage(body:GuiContainer, ?head:String = null) {
		Lib.println("<!doctype html>");
		Lib.println("<html>");
		Lib.println("	<head>");
		Lib.println("		<script type='text/javascript' src='https://ajax.googleapis.com/ajax/libs/jquery/1.5.0/jquery.min.js'></script>");
		if (head != null) Lib.print("		"+StringTools.replace(head, "\n", "\n		"));
		Lib.println("		<script type='text/javascript' src='webmonitormaster.js'></script>");
		Lib.println("		<style type='text/css'>");
		Lib.println("			" + StringTools.replace(body.writeCss(), "\n", "\n			"));
		Lib.println("		</style>");
		Lib.println("	</head>");
		Lib.println("	<body>");
		Lib.println("		" + StringTools.replace(body.write(), "\n", "\n		"));
		Lib.println("		<script type='text/javascript'>");
		Lib.println("			var root = webmonitormastergui.MasterGui.register('" + Serializer.run(body) + "');");
		Lib.println("			webmonitormastergui.GuiContainer._mId = " + GuiContainer._mId + ";");
		Lib.println("		</script>");
		Lib.println("	</body>");
		Lib.println("</html>");
	}
	#end
	
	#if js
	static public function register(c:String) {
		root = Unserializer.run(c);
		root.init();
		return root;
	}
	
	static public function store(username:String, sessionId:String) {
		MasterGui.username = username;
		MasterGui.sessionId = sessionId;
		if (LocalStorage.supported()) {
			LocalStorage.setItem('username', MasterGui.username);
			LocalStorage.setItem('sessionId', MasterGui.sessionId);
		}
		
	}
	
	static public function backendLogin(username:String, password:String, f:Dynamic->Void) {
		var s1:String = Md5.encode(Std.string(Date.now().getTime()));
		var credentials:String = Tea.encrypt(s1 + ":" + Md5.encode(s1), password);
		var req = JQueryS.ajax({dataType: "text", async: true, cache: false, data: {action: "initsession", username: username, cred: credentials} } );
		req.complete(callback(backendResponce,f));
	}
	
	static public function backend(data:Dynamic, f:Dynamic->Void) {
		var s1:String = Md5.encode(Std.string(Date.now().getTime()));
		var credentials:String = Tea.encrypt(s1 + ":" + Md5.encode(s1), sessionId);
		data.username = username;
		data.session = true;
		var req = JQueryS.ajax({dataType: "text", async: true, cache: false, data: data} );
		req.complete(callback(backendResponce,f));
	}
	
	static private function backendResponce(f:List<Dynamic>->Void, responce:Dynamic) {
		var data:List<String> = responce.responseText.split("/n");
		var out:List<Dynamic> = new List();
		try {
			for (item in data) {
				out.push(Unserializer.run(item));
			}
		} catch (e:Fatal) {
			switch (e.type) {
				case UNAUTHORISED(spec): out.push(e);
				default: trace(e.message);
			}
		}
		f(out);
	}
	#end
}
