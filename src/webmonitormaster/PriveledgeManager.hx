package webmonitormaster;

/**
 * ...
 * @author othrayte
 */

class PriveledgesManager extends php.db.Manager<Priveledge> {
    public function new() {
        super(User);
    }
	
	public function get(priveledgeName:String, user:User) {
		return object(select("name = " + priveledgeName + "and userid = " + user.id));
	}
	
	public function set(priveledgeName:String, user:User) {
		if (object(select("name = " + priveledgeName + "and userid = " + user.id)) == null {
			var p = new Priveledge();
			p.name = priveledgeName;
			p.insert();
		}
	}
	
	public function remove(priveledgeName:String, user:User) {
		var p = object(select("name = " + priveledgeName + "and userid = " + user.id));
		if (p != null) p.delete();		
	}
	
}