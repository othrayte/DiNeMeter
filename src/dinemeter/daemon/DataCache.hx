package dinemeter.daemon;
import cpp.io.File;
import cpp.vm.Mutex;
import dinemeter.client.BackendRequest;
import haxe.io.Eof;
import haxe.Serializer;
import haxe.Unserializer;

/**
 * ...
 * @author Adrian Cowan (Othrayte)
 */

class CacheItem {
	public var data:List<DataRecord>;
	public var usernames:List<String>;
	public var trust:Int;
	public function new(data:List<DataRecord>, usernames:List<String>, trust:Int) {
		this.data = data;
		this.usernames = usernames;
		this.trust = trust;
	}
}

class DataCache {
	static var outfile:String;
	static var cacheLock:Mutex = new Mutex();
	static var ready:Bool = false;
	static var tempCache:List<CacheItem> = new List();
	
	static public function setFile(path:String) {
		if (ready) return false;
		if (!cacheLock.tryAcquire()) return false;
		outfile = path;
		cacheLock.release();
		return true;
	}
	
	static public function send() {
		if (!ready) return false;
		cacheLock.acquire();
		var raw = File.getContent(outfile);
		var lines = raw.split("\n");
		for (line in lines) {
			var item = Unserializer.run(line);
			if (Std.is(item, CacheItem)) {
				BackendRequest.putData(item.usernames, item.data, item.trust, callback(sendResponce, cast(item, CacheItem)));
			}
		}
		var out = File.write(outfile, false);
		out.writeString("");
		out.close();
		cacheLock.release();
		return true;
	}
	
	static function sendResponce(info:CacheItem, responce:Array<Dynamic>) {
		var failed:Bool = false;
		for (item in responce) {
			if (Std.is(item, Fatal)) {
				trace(item.message);
				failed = true;
			} else if (Std.is(item, Eof)) {
				trace("Eof error!?");
				failed = true;
			}
		}
		if (failed) {
			append(info);			
		}
	}
	
	static public function append(info:CacheItem) {
		if (!ready) {
			tempCache.add(info);
			return false;
		} else {
			if (!cacheLock.tryAcquire()) {
				tempCache.add(info);
				return false;
			}
			var out = File.append(outfile, false);
			out.writeString(Serializer.run(info) + "\n");
			while (!tempCache.isEmpty()) out.writeString(Serializer.run(tempCache.pop()) + "\n");
			out.close();
			cacheLock.release();
		}
		return true;
	}
}