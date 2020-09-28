<?php
//------------------
// naviClient class 
//
// 
class naviClient {
	private $client_id = 0;
	private $safety_key = "";
	private $time_zone = 3;
	private $data_dir = "";
	private $order_dir = "";
	private $routes_dir = "";
	private $product_dir = "";
	
	function __construct($_id, $_safety_key, $_time_zone = null) {
		if (strlen($_safety_key) != 36) throw new Exception("Wrong safety key");
		$this->client_id = $_id;
		$this->safety_key = $_safety_key;
		$this->time_zone = $_time_zone;
		$this->data_dir = "../" . $this->client_id . "-data/";
		$settings = parse_ini_file($this->data_dir . "settings.ini", true);
		if (array_key_exists("dir", $settings)) {
			if (array_key_exists("products", $settings["dirs"])) $this->product_dir = $this->data_dir . $settings["dirs"]["products"];
			if (array_key_exists("orders", $settings["dirs"])) $this->product_dir = $this->data_dir . $settings["dirs"]["orders"];
			if (array_key_exists("routes", $settings["dirs"])) $this->product_dir = $this->data_dir . $settings["dirs"]["routes"];
		}
/*		var_dump($settings);
		$this->dblink = new mysqli("localhost", $dbsettings["user"], $dbsettings["pwd"], $dbsettings["database"]);
		if ($this->dblink->connect_errno) throw new Exception("Unable connect to database: " . $this->dblink->connect_errno . " - " . $this->dblink->connect_error);
		$this->dblink->set_charset("utf-8");
		$this->dblink->query("set names utf8");
		if (!is_null($this->time_zone)) $this->dblink->query("SET @@session.time_zone='" . ((0 < $this->time_zone)? "+":"") . $this->time_zone . ":00';");
*/
	}
	function __destruct() {
//		$this->dblink->close();
	}
	function getRoutes($_order) {
		if (!$z = simplexml_load_file($this->routes_dir . 'route-' . $_order . '.xml')) throw new Exception ("XML route-" . $_order . " is wrong!");
		$ret = array();
		foreach ($z as $res) $ret[] = ((array) $res->attributes())['@attributes'];
		return $ret;
	}
	function getRoute($_order, $_id) {
		if (!$z = simplexml_load_file($this->routes_dir . 'route-' . 'route-' . $_order . '.xml')) throw new Exception ("XML route-" . $_order . " is wrong!");
		$found = $z->xpath("//route[@id='" . $_order . "." . $_id . "']");
		if (!$found)  throw new Exception ("Route " . $_order . "." . $_id . " not found!");
		return $found[0];
	}
}
?>