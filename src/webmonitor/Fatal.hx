package webmonitor;

/**
 *  This file is part of WebMonitor.
 *
 *  WebMonitor is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  any later version.
 *
 *  WebMonitor is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with WebMonitor.  If not, see <http://www.gnu.org/licenses/>.
 *
 * @author Adrian Cowan (othrayte)
 */

class Fatal {
	public var type:FatalError;
	public var code:Int;
	public var message:String;
	public function new(type:FatalError) {
		this.type = type;
		switch (type) {
			case SERVER_ERROR(specific): 
				code = 500;
				message = "Server error: ";
				switch (specific) {
					case UNKNOWN_DB_VERSION: message += "unknown databse version";
					case DB_VERSION_OLD: message += "DB version too old";
					case DEFAULT_CONNECTION_MISSING: message += "unable to get default connection";
					case DB_LOGIN_ERROR(msg): message += "DB login failed: '" + msg + "'";
					case UPDATE_FAILED: message += "update failed";
					case UPDATE_FAILED_BETWEEN(oldVer, newVer): message += "update failed from db version " + oldVer + " to version " + newVer;
				}
			case UNAUTHORISED(specific):
				code = 401;
				message = "Unauthorised: ";
				switch (specific) {
					case NO_USER(username): message += "no user named "+username;
					case SESSION_IP_WRONG: message += "session not initiated from client ip";
					case SESSION_TIMEOUT: message += "session has timed out";
					case INVALID_CRED: message += "credentials not valid";
					case INVALID_CRED_STAGE_1: message += "invalid credentials, stage 1";
					case INVALID_CRED_STAGE_2: message += "invalid credentials, stage 2";
					case USER_NOT_GRANTED(priv): message += "user not granted priveledge '" + priv + "'";
					case USER_NOT_ALLOWED(action, username): message += "user not granted rights to '" + action + "' for user '" + username + "'";
				}
			case INVALID_REQUEST(specific):
				code = 400;
				message = "Invalid request: ";
				switch (specific) {
					case NO_USERNAME_SUPPLIED: message += "no username supplied";
					case NO_CRED_SUPPLIED: message += "no user credentials supplied";
					case INVALID_ACTION(action): message += "invalid action '" + action + "'";
					case INVALID_CONTAINER(container): message += "invalid container '" + container + "'";
					case INVALID_DATA(action): message += "invalid data supplied to '" + action + "'";
					case MISSING_USERNAMES(action): message += "must pass 'usernames' to '" + action + "'";
					case MISSING_DATA(action): message += "must pass 'data' to '" + action + "'";
					case MISSING_TRUST_LEVEL(action): message += "must pass 'trustLevel' to '" + action + "'";
					case MISSING_ID_START: message += "must pass 'idStart' to the container retriever";
					case USER_NOT_IN_CONNECTION(username): message += "no user '" + username + "' on this connection";
					case CONNECTION_NOT_FOUND: message += "unable to find requested connection";
				}
		}
	}
}

enum FatalError {
	SERVER_ERROR(specific:ServerError);
	UNAUTHORISED(specific:AuthError);
	INVALID_REQUEST(specific:InvalidRequestError);
}

enum ServerError {
	// Specific types of server error
	UNKNOWN_DB_VERSION;
	DB_VERSION_OLD;
	DEFAULT_CONNECTION_MISSING;
	DB_LOGIN_ERROR(msg:String);
	UPDATE_FAILED;
	UPDATE_FAILED_BETWEEN(oldVer:Int, newVer:Int);
}

enum AuthError{
	// Specific types of auth error
	NO_USER(username:String);
	SESSION_IP_WRONG;
	SESSION_TIMEOUT;
	INVALID_CRED;
	INVALID_CRED_STAGE_1;
	INVALID_CRED_STAGE_2;
	USER_NOT_GRANTED(priv: String);
	USER_NOT_ALLOWED(action:String, username:String);
}

enum InvalidRequestError{
	// Specific types of invalid request error
	INVALID_ACTION(action:String);
	INVALID_CONTAINER(container:String);
	INVALID_DATA(action:String);
	NO_USERNAME_SUPPLIED;
	NO_CRED_SUPPLIED;
	MISSING_USERNAMES(action:String);
	MISSING_DATA(action:String);
	MISSING_TRUST_LEVEL(action:String);
	MISSING_ID_START;
	USER_NOT_IN_CONNECTION(username:String);
	CONNECTION_NOT_FOUND;
}