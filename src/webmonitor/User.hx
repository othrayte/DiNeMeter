package webmonitor;

import haxe.BaseCode;
import haxe.io.BytesInput;
import haxe.Md5;
import php.Web;

import webmonitor.crypto.Tea;

using webmonitor.master.backend.StoredDataRecord;

/**
 *  This file is part of WebMonitor.
 *
 *  WebMonitor is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Affero General Public License as
 *  published by the Free Software Foundation, either version 3 of the
 *  License, or any later version.
 *
 *  WebMonitor is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Affero General Public License for more details.
 *
 *  You should have received a copy of the GNU Affero General Public License
 *  along with WebMonitor.  If not, see <http://www.gnu.org/licenses/>.
 *
 * @author Adrian Cowan (othrayte)
 */

class User {	
	public var id:Int;
	public var name:String;
	public var password:String;
	public var downQuota:Int;
	public var upQuota:Int;
	public var connectionId:Int;
	public var sessionId:String;
	public var sessionIp:String;
	public var sessionTimeout:Int;
	

	public function new() 	{

	}
}