package webmonitormaster;

/**
 * ...
 * @author othrayte
 */

class PriveledgeManager extends php.db.Manager<Priveledge> {
    public function new() {
        super(Priveledge);
    }
	
	public function getPriveledge(priveledgeName:String, user:User) {
		return object(select("name = " + quote(priveledgeName) + " and userid = " + user.id), true);
	}
	
	public function set(priveledgeName:String, user:User) {
		if (object(select("name = " + quote(priveledgeName) + " and userid = " + user.id), true) == null) {
			var p = new Priveledge();
			p.name = priveledgeName;
			p.userId = user.id;
			p.insert();
		}
	}
	
	public function remove(priveledgeName:String, user:User) {
		var p = object(select("name = " + quote(priveledgeName) + " and userid = " + user.id), true);
		if (p != null) p.delete();		
	}
	
}