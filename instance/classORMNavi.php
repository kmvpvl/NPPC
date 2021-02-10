<?php
class ORMNaviException extends Exception {

}
class ORMNaviUser {
	function __debugInfo() {
		return [];
	}
}
class ORMNaviMessage implements JsonSerializable {
    public function jsonSerialize() {
        return [];
    }
	function __debugInfo() {
		return [];
	}
}
class ORMNaviRoute implements JsonSerializable {
    public function jsonSerialize() {
        return [];
    }
	function __debugInfo() {
		return [];
	}
}
class ORMNaviOrder implements JsonSerializable {
    public function jsonSerialize() {
        return [];
    }
	function __debugInfo() {
		return [];
	}
	public function getRoute($order_id) {

	}
	public function addProduct(string $prodmat_ref, float $count) {

	}
}
class ORMNaviFactory {
    // factory mnemonic unique ID in this instance
	private $factory = "";
	// client ID one-to-one with factory.Filled from database. An ID in database
	private $client_id = -1;
	private $user = "";
	private $user_id = -1;
	// time zone for setting in database. Usually for client request. Helps to do no calculation on client  
	private $time_zone = 0;
	// root folder of factory 
	private $data_dir = "";
	// relative path to orders' folder
	private $order_dir = "";
	// relative path to the routes' folder
	private $routes_dir = "";
	// relative path to the products' folder
	private $product_dir = "";
	// loaded factory.xml in root folder
	private $factory_xml;
	function __construct(string $user, string $password, string $factory, ?DateTimeZone $time_zone = null) {
		$this->factory = $factory;
		$this->user = $user;
		$this->time_zone = $time_zone;
		// set root folder
		$this->data_dir = "../" . $this->factory . "-data/";
		// finding and parsing  settings.ini for database settings & folders settings
		$settings = parse_ini_file($this->data_dir . "settings.ini", true);
		if (!$settings) new ORMNaviException("Settings INI-file not found!");
		if (array_key_exists("dir", $settings)) {
			if (array_key_exists("products", $settings["dir"])) $this->product_dir = $this->data_dir . $settings["dir"]["products"];
			if (array_key_exists("orders", $settings["dir"])) $this->orders_dir = $this->data_dir . $settings["dir"]["orders"];
			if (array_key_exists("routes", $settings["dir"])) $this->routes_dir = $this->data_dir . $settings["dir"]["routes"];
			if (array_key_exists("messages", $settings["dir"])) $this->message_dir = $this->data_dir . $settings["dir"]["messages"];
		}
		// loading factory.xml
		$this->factory_xml = simplexml_load_file($this->data_dir . 'factory.xml');
		if (!$this->factory_xml) throw new ORMNaviException ("Wrong factory XML: " . $this->data_dir . 'factory.xml');
		$found = $this->factory_xml->xpath("//user[@id='" . $user . "']");
		if (!$found) throw new ORMNaviException ("User " . $user . ' not found');
		//checking md5 user hash
		$hash = md5($user . $password);
		if ((string) $found[0]["md5"] != $hash) throw new ORMNaviException ("Password incorrect! " . $hash);
//		var_dump($settings);
        // connecting to database
        $host = "";
        $database = "";
        $dbuser = "";
        $dbpassword = "";
		
		if (array_key_exists("database", $settings)) {
			if (array_key_exists("host", $settings["database"])) $host = $settings["database"]["host"];
			if (array_key_exists("database", $settings["database"])) $database = $settings["database"]["database"];
			if (array_key_exists("user", $settings["database"])) $dbuser = $settings["database"]["user"];
			if (array_key_exists("password", $settings["database"])) $dbpassword = $settings["database"]["password"];
		} else throw new ORMNaviException ("database settings are absent"); 
		
		$this->dblink = new mysqli($host, $dbuser, $dbpassword, $database);
		if ($this->dblink->connect_errno) throw new ORMNaviException("Unable connect to database (" . $host . " - " . $database . "): " . $this->dblink->connect_errno . " - " . $this->dblink->connect_error);
		$this->dblink->set_charset("utf-8");
		$this->dblink->query("set names utf8");
		if (!is_null($this->time_zone)) $this->dblink->query("SET @@session.time_zone='" . $this->time_zone->getName() . "';");
		// loading client ID
		$x = $this->dblink->query("select getClientID('" . $this->factory . "') as client_id;");
		
		if (!$x) throw new ORMNaviException("Factory '" . $this->factory . "' not found in '" . $database. "': " . $this->dblink->errno . " - " . $this->dblink->error);
		$this->client_id = $x->fetch_assoc()["client_id"];
		$x->free_result();
		$x = $this->dblink->next_result();
		$this->user_id = $this->getUserIDByName($this->user);
	}
	function __destruct() {

	}
	public function createOrder(string $order_number, string $customer_ref, DateTime $deadline ): ORMNaviOrder {

	}

	public function getOrder(string $order_number) :? ORMNaviOrder {

	}
	protected function getUserIDByName(string $user_name): int {
		$x = $this->dblink->query("select getUserID(" . $this->client_id . ", '" . $this->user . "') as user_id;");
		if (!$x) throw new Exception("User '" . $this->user . "' not found in database. : " . $this->dblink->errno . " - " . $this->dblink->error);
		$user_id = $x->fetch_assoc()["user_id"];
		$x->free_result();
		$x = $this->dblink->next_result();
		return $user_id;
	}
}
?>