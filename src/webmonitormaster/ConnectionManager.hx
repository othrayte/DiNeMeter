package webmonitormaster;

/**
 * ...
 * @author othrayte
 */

class ConnectionManager extends php.db.Manager<Connection> {
    public function new() {
        super(Connection);
    }
	
	
	public function byName(name: String) {
		return object(select("name = " + name), true);
    }
}