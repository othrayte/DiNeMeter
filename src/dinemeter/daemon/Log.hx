package dinemeter.daemon;

import cpp.FileSystem;
import cpp.io.File;

import dinemeter.Config;
import dinemeter.Fatal;
import dinemeter.client.BackendRequest;

/**
 *  This file is part of DiNeMeterDaemon.
 *
 *  DiNeMeterDaemon is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  any later version.
 *
 *  DiNeMeterDaemon is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with DiNeMeterDaemon.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * @author Adrian Cowan (Othrayte)
 */

class Log {
    static var current:Log;
    static var username:String;
    var errorPath:String;
    var logPath:String;
    var reportErrors:Bool;
    
    static public function setup(config:Config) {
        try {
            username = config.get("username");
            new Log(config.get("log"), config.get("error-log"), config.get("report-errors"));
        } catch (e:Dynamic) {
            trace("Unable to setup log file " + Std.string(e));
            File.stdin().readLine();
        }
    }
    
    public function new(logPath:String, errorPath:String, ?reportErrors:Bool = true) {
        this.errorPath = errorPath;
        this.logPath = logPath;
        if (FileSystem.exists(logPath)) {
            if (FileSystem.kind(logPath + ".old") == kfile) {
                FileSystem.deleteFile(logPath + ".old");
            }
            FileSystem.rename(logPath, logPath + ".old");
        }
        if (logPath != null) {
            var f = File.write(logPath, false);
            f.close();
        }
        this.reportErrors = reportErrors;
        current = this;
    }
    
    public function message(message:String) {
        if (logPath != null) {
            var f = File.append(logPath, false);
            f.writeString("-- "+Date.now().toString() + " : " + message + "\n");
            f.close();
        }
    }
    
    static public function mes(message:String) {
        current.message(message);
    }
    
    public function error(type:Fatal, ?otherMessage:String = null) {
        var message:String = "";
        message = type.message;
        if (otherMessage != null) {
            message += "\n" + otherMessage;
        }
        if (logPath != null) {
            var log:String;
            if ((log = File.getContent(logPath)) != null) {
                message += "\n\nTrace";
                message += "\n" + log;
            }
        }
        if (errorPath != null) {
            var f = File.append(errorPath, false);
            f.writeString("-- "+Date.now().toString() + "\n" + message + "\n\n");
            f.close();
        }
        if (reportErrors) report(type, "Error reported from user " + username + " at "+Date.now().toString() + "\n" + message);
    }
    
    static public function err(type:Fatal, ?otherMessage:String = null) {
        current.error(type, otherMessage);
    }
    
    function report(type:Fatal, message:String) {
        BackendRequest.reportError(type, message, function(res) { trace(res); } );
    }
}