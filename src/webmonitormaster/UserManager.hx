package webmonitormaster;

/**
 * ...
 * @author othrayte
 */

class UserManager extends php.db.Manager<User> {
    public function new() {
        super(User);
    }
	
	
    
	public function byName(name: String, ?connection:Connection) {
		if (connection != null) return object(select("name = " + name + " and connectionId = " + connection.id), true); 
        return object(select("name = " + name), true);
    }
}