package webmonitormaster;

import php.Lib;

/**
 * ...
 * @author othrayte
 */

class Main {
	
	static function main() {
		var params = php.Web.getParams();
		if (params.exists('action')) {
			var action = params.get('action').toLowerCase();
			try {
				if (action == 'getdata') {
					Master.getData(params);
				} else if (action == 'changedata') {
					Master.changeData(params);
				} else if (action == 'setdata') {
					Master.setData(params);
				} else if (action == 'getstats') {
					Master.getStats(params);
				} else if (action == 'readsetting') {
					Master.readSetting(params);
				} else if (action == 'changesetting') {
					Master.changeSetting(params);
				}
			} catch (e) {
				
				
			}
		}
		var start = params.exists('start') ? params.get('start') : null;
		
	}

}