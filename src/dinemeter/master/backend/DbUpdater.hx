package dinemeter.master.backend;

import haxe.io.Eof;
import php.FileSystem;
import php.io.File;
import php.io.FileInput;
import dinemeter.Fatal;

using dinemeter.Util;

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
 * @author Adrian Cowan (othrayte)
 */

class DbUpdater {
	public static function updateDb(desiredVersion:Int) {
		if (Version.manager.count() == 0) throw new Fatal(SERVER_ERROR(UNKNOWN_DB_VERSION));
		var dbVersion:Int = php.db.Manager.cnx.request("SELECT version FROM `version` LIMIT 1").getIntResult(0);
		while (dbVersion != desiredVersion) {
			if (dbVersion != desiredVersion) {
				if (FileSystem.exists("./updates/db/" + dbVersion + ".wmdbupdate")) {
					var file:FileInput = File.read("./updates/db/" + dbVersion + ".wmdbupdate", false);
					// Newer version avaliable
					"DB being upgraded to a newer version".important();
					updateWithin(file, dbVersion, desiredVersion);
				} else {
					throw new Fatal(SERVER_ERROR(DB_UPGRADE_PATH_MISSING(dbVersion)));
				}
			}
			var version = php.db.Manager.cnx.request("SELECT version FROM `version` LIMIT 1").getIntResult(0);
			if (dbVersion == version) {
				throw new Fatal(SERVER_ERROR(DB_UPGRADE_PATH_MISSING(dbVersion)));
			} else {
				dbVersion = version;
			}
		}
	}	
	private static function updateWithin(file:FileInput, currentVersion:Int, desiredVersion) {
		//TODO: Test updating more than one update at a time
		var executing:Bool = false;
		var oldVersion:Int = currentVersion;
		var nextVersion:Int = currentVersion;
		try {
			do {
				var command:String = nextUpdateCommand(file);
				if (command.charAt(0) == '@') {
					if (executing) {
						// Check last
						var dbVersion:Int = php.db.Manager.cnx.request("SELECT version FROM `version` LIMIT 1").getIntResult(0);
						if (dbVersion == nextVersion) {
							("Successfully updated from db version " + oldVersion + " to version " + dbVersion).important();
							oldVersion = nextVersion;
							php.db.Manager.cnx.commit();
						} else {
							throw new Fatal(SERVER_ERROR(UPDATE_FAILED));
							php.db.Manager.cnx.rollback();
						}
						executing = false;
					}
					// Parse
					var oldV:Int = Std.parseInt(command.substr(1).split(":")[0]);
					var newV:Int = Std.parseInt(command.substr(1).split(":")[1]);
					// Check next
					if (oldV == oldVersion && newV <= desiredVersion) {
						nextVersion = newV;
						executing = true;
						php.db.Manager.cnx.startTransaction();
					}
				} else if (executing) {
					php.db.Manager.cnx.request(command);
				}
			} while (currentVersion < desiredVersion);
		} catch (e:Eof) {
			if (executing) {
				var dbVersion:Int = php.db.Manager.cnx.request("SELECT version FROM `version` LIMIT 1").getIntResult(0);
				if (dbVersion == nextVersion) {
					Util.important("Successfully updated from db version " + oldVersion + " to version " + dbVersion);
					oldVersion = nextVersion;
					php.db.Manager.cnx.commit();
				} else {
					php.db.Manager.cnx.rollback();
					throw new Fatal(SERVER_ERROR(UPDATE_FAILED_BETWEEN(oldVersion, nextVersion)));
				}
			}
		} catch (e:String ) {
			Util.important("Mysql error: " + e);
		}
	}
	
	private static function nextUpdateCommand(file:FileInput):String {
		var out:String = "";
		var another:Bool;
		do {
			another = true;
			var tmp:String;
			do {
				tmp = StringTools.trim(file.readLine());
			} while (tmp.charAt(0) == '#' || tmp.length == 0);
			out += " " + tmp;
			out = StringTools.ltrim(out);
			if (out.charAt(0) == '@' || out.charAt(out.length - 1) == ';') another = false;
		} while (another);
		return out;
	}	
}