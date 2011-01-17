package webmonitormaster;

import php.Lib;
import php.Sys;
import php.Web;

/**
 * ...
 * @author othrayte
 */

class Main {
	
	static function main() {
		var params = php.Web.getParams();
		if (params.exists('show')) {
			
			
			
		} else if (params.exists('action')) {
			try {
				var username = params.exists('username') ? params.get('username') : throw new Fatal(401, "Unauthorised - no username supplied");
				var credentials = params.exists('cred') ? params.get('cred') : throw new Fatal(401, "Unauthorised - no user credentials supplied");
				var connection = params.exists('connection') ? Master.getConnection(params.get('connection')) : Master.getConnection();
				
				Master.login(username, credentials, connection);
				
				
				var action = params.get('action').toLowerCase();
				if (action == 'getdata') {
					Master.getData(params);
				} else if (action == 'changedata') {
					Master.changeData(params);
				} else if (action == 'setdata') {
					Master.putData(params);
				} else if (action == 'putstats') {
					Master.getStatistic(params);
				} else if (action == 'readsetting') {
					Master.readSetting(params);
				} else if (action == 'changesetting') {
					Master.changeSetting(params);
				}
			} catch (e:Fatal) {
				Web.setReturnCode(e.code);
				Lib.println(e.message);
			}
		}
		
	}

}