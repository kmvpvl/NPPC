<?php


//------------------
// naviClient class 
//
// 
class naviClient {
    const MESSAGE_INFO = 'info';
    const MESSAGE_WARNING = 'warning';
    const MESSAGE_CRITICAL = 'critical';

	private $factory = "";
	private $time_zone = 0;
	private $data_dir = "";
	private $order_dir = "";
	private $routes_dir = "";
	private $product_dir = "";
	private $message_dir = "";
	private $factory_xml;
	
	function __construct(string $_user, string $_password, string $_factory, $_time_zone = null) {
		$this->factory = $_factory;
		$this->time_zone = $_time_zone;
		$this->data_dir = "../" . $this->factory . "-data/";
		$settings = parse_ini_file($this->data_dir . "settings.ini", true);
		if (array_key_exists("dir", $settings)) {
			if (array_key_exists("products", $settings["dir"])) $this->product_dir = $this->data_dir . $settings["dir"]["products"];
			if (array_key_exists("orders", $settings["dir"])) $this->product_dir = $this->data_dir . $settings["dir"]["orders"];
			if (array_key_exists("routes", $settings["dir"])) $this->product_dir = $this->data_dir . $settings["dir"]["routes"];
			if (array_key_exists("messages", $settings["dir"])) $this->message_dir = $this->data_dir . $settings["dir"]["routes"];
		}
		$this->factory_xml = simplexml_load_file($this->data_dir . 'factory.xml');
		if (!$this->factory_xml) throw new Exception ("Wrong factory XML: " . $this->data_dir . 'factory.xml');
		$found = $this->factory_xml->xpath("//user[@id='" . $_user . "']");
		if (!$found) throw new Exception ("User " . $_user . ' not found');
		$hash = md5($_user . $_password);
		if ((string) $found[0]["md5"] != $hash) throw new Exception ("Password incorrect! " . $hash);
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
	
	function __get($prop) {
		switch ($prop) {
			case "factoryMap":
				return $this->factory_xml["map"];
			case "factoryName":
				return $this->factory_xml["name"];
			case "factorySatellite":
				return $this->factory_xml["img"];
			
		}
	}
	
	function createMessage($_messageType) {
	}
}
?>