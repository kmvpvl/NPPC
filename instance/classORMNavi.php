<?php
class ORMNaviException extends Exception {

}
class ORMNaviTag implements JsonSerializable {
	protected $factory; 
	protected $tag;
	function __construct(ORMNaviFactory $factory, string $tag){
		$this->factory = $factory;
		if (!strpos($tag, "@")) {
		//	$tag = str_replace("\"", "", $tag);
		}
		$this->tag = $tag;
	}
    public function jsonSerialize() {
        return [
			"tag"=>$this->tag
		];
    }
	function __debugInfo() {
		return [];
	}
	function __get($name) {
		switch ($name) {
			case 'tag':
				return $this->tag;
				break;
			
			default:
				# code...
				break;
		}
	}
}
class ORMNaviUser implements JsonSerializable {
	protected $hash;
	protected $user_name;
	protected $factory;
	protected $roles;
	protected $subscriptions;
	function __construct(ORMNaviFactory $factory, string $user_name, string $password) {
		$this->user_name = $user_name;
		$this->factory = $factory;
		$this->hash = md5($user_name . $password);
	}
	protected function getUserByName() {
		$sql = "call getUser('".$this->factory->name."', '".$this->user_name."');";
		$x = $this->factory->dblink->query($sql);
		if (!$x) throw new ORMNaviException("User '" . $this->user_name . "' not found in factory '" . $this->factory->name. "': " . $this->dblink->errno . " - " . $this->dblink->error);
		$y = $x->fetch_assoc();
		$x->free_result();
		$x = $this->factory->dblink->next_result();
		return $y;
	}
	public function authorize() {
		$user = $this->getUserByName();
		if ($user["hash"] != $this->hash) throw new ORMNaviException("User was not found or password was incorrect");
		$this->roles = $user["roles"];
		$this->subscriptions = $user["subscriptions"];
	}
	function __debugInfo() {
		return [
			"factory" => $this->factory->name,
			"username"=> $this->user_name,
			"hash"=> $this->hash,
			"roles"=> $this->roles,
			"subscriptions"=> $this->subscriptions
		];
	}
	public function jsonSerialize() {
		return [
			"factory" => $this->factory->name,
			"name"=> $this->user_name,
			"hash"=> $this->hash,
			"roles"=> $this->roles,
			"subscriptions"=> $this->subscriptions
		];
    }
	function __get($name) {
		switch ($name) {
			case 'name':
				return $this->user_name;

			case 'tag':
				return "@".$this->user_name;
				
			case 'subscriptionsForSearch':
				$arr = explode(";", $this->subscriptions);
				$r = "";
				foreach ($arr as $value) {
					if ($value) $r .= "\"". $value."\"";
				}
				return $this->factory->dblink->real_escape_string($r);
			default:
				# code...
				break;
		}
	}
}
abstract class ORMNaviMessageType {
	const INFO = "INFO";
	const WARNING = "WARNING";
	const CRITICAL = "CRITICAL";
}
class ORMNaviMessage implements JsonSerializable {
	protected $id;
	protected $factory;
	protected $body;
	protected $type;
	protected $from;
	protected $tags;
	protected $message_time;
	protected $thread_id;
	protected $read_time;
	protected function _arrayImport(array $a) {
		foreach ($a as $key=>$value) {
			if (is_null($this->$key)) $this->$key = $value;
		}
	}
	static public function createFromArray(ORMNaviFactory $factory, array $a) {
		//$u = new ORMNaviUser($factory, $a["from"], "");
		$m = new self($factory, $a["body"], $a["message_type"], $a["from"]);
		$m->_arrayImport($a);
		return $m;
	}
	/**
	 * @param {ORMNaviFactory} $factory is object ORMNaviFactory for db operations
	 */
	function __construct(ORMNaviFactory $factory 
		, string $message_text
		, string $message_type = ORMNaviMessageType::INFO
		, ?string $user_from = null
		, ?array $tags = null
	) {
		$this->body = $message_text;
		$this->factory = $factory;
		$this->type = $message_type;
		if (is_null($user_from)) $user_from = $factory->user->name;
		$this->from = $user_from;
		if (is_null($tags)) $tags = array();
		$this->tags = $tags;
		$this->extractTags();
	}
	protected function extractTags(){
		$arr = array();
		preg_match_all('/[@]"[^"]+"|[#][\w\-\/]+|[@][\w]+/imu', $this->body, $arr);
		foreach ($arr[0] as $value) {
			$this->tags[] = new ORMNaviTag($this->factory, $value);
		}
	}
	/**
	 * 
	 */
	protected function implode_tags() {
		$r = array();
		foreach ($this->tags as $value) {
			$r[] = $value->tag;
		}
		return implode(";", $r);
	}
	public function send(){
		$sql = "call addMessage('" . $this->factory->name . "', '" . $this->from . "', '" . $this->type . "', '" . $this->body . "', '".$this->implode_tags()."', null)";
	    $x = $this->factory->dblink->query($sql);
	    if ($this->factory->dblink->errno || !$x) throw new ORMNaviException("Could not create message: " . $this->factory->dblink->errno . " - " . $this->factory->dblink->error);
		$y = $x->fetch_assoc();
		$this->_arrayImport($y);
		$x->free_result();
		$this->factory->dblink->next_result();
		return $this->id;
	}
	public function dismiss(){
		$user = $this->factory->user;
		if (!$this->sent) throw new ORMNaviException("Message was not sent");
		$y = $this->factory->dismissMessage($this->id);
		$this->_arrayImport($y);
		return $this->id;
	}
	function __get($name) {
		switch ($name) {
			case 'id':
				return $this->id;
				break;
			
			case 'sent':
				return !is_null($this->id);
				break;
			
			case 'readBy':
				# code...
				break;
			
			default:
				# code...
				break;
		}
	}
    public function jsonSerialize() {
        return [
			"factory"=>$this->factory->name,
			"id"=>$this->id,
			"body"=>$this->body,
			"type"=>$this->type,
			"tags"=>$this->tags,
			"from"=>$this->from,
			"message_time"=>$this->message_time,
			"read_time"=>$this->read_time,
			"thread_id"=>$this->thread_id
		];
    }
	function __debugInfo() {
		return jsonSerialize();
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
abstract class ORMNaviOrderStates {
	const ASSIGNED = "ASSIGNED";
	const PAUSED = "PAUSED";
	const ABANDONED = "ABANDONED";
}
class ORMNaviOrder implements JsonSerializable {
	protected $factory = null;
	protected $id = null;
	protected $number = null;
	protected $state = null;
	protected $deadline = null;
	protected $baseline = null;
	protected $estimated = null;
	protected $priority = null;
	protected $comment = null;
	protected $current_route = null;
	protected $xml = null;
	protected $routes_xml = null;

	protected function _arrayImport(array $a) {
		foreach ($a as $key=>$value) {
			if (property_exists($this, $key)) {

				$this->$key = $value;
			}
		}
	}

	function __goRoundProdLevel(SimpleXMLElement $product, string $outline, SimpleXMLElement $order) {
		$ret = [];
		$ret["cost"] = 0;
		$i = 1;
		foreach ($product as $p) {
			$cost = 0;
			$out = "";
			if (!is_null($p["id"])) $out = $p["id"]; 
			else $out = "".$i;
			$tmp = $order->addChild($p->getName());
			$tmp->addAttribute("id", $outline.".".$out);
			if (!is_null($p["ref"])) {
				$tmp->addAttribute("ref", $p["ref"]);
				$r = $this->factory->getMDMRef($p["ref"]);
				if ($p->getName()== "operation") {
					if (is_null($r["cost"])) throw new ORMNaviException("Operation id = '".$p["ref"]."' have no cost");
					if (is_null($r["duration"])) throw new ORMNaviException("Operation id = '".$p["ref"]."' have no duration");
					if(!is_null($p["cost"])) $tmp->addAttribute("cost", $p["cost"]);
					else $tmp->addAttribute("cost", $r["cost"]);
					if(!is_null($p["duration"])) $tmp->addAttribute("duration", $p["duration"]);
					else $tmp->addAttribute("duration", $r["duration"]);
					$cost += floatval($tmp["cost"]);
					$facop = $this->factory->getWorkcentersOfOperation($p["ref"]);
					foreach ($facop as $wc) {
						if ($wc->getName() != "workcenter") throw new ORMNaviException("Tag operation ref = '".$p["ref"]."' in factory xml must be a child in tag workcenter");
						$tmp1 = $tmp->addChild("workcenter");
						$tmp1->addAttribute("ref", $wc["id"]);
					}
				}
				$o = $this->__goRoundProdLevel($r, $outline.".".$out, $tmp);
				$cost += $o["cost"];
				if ($p->getName() == "material") {
					if (is_null($p["count"])) $tmp->addAttribute("count", 1);
					else $tmp->addAttribute("count", $p["count"]);
					$tmp->addAttribute("cost", $r["cost"]);
					$cost += floatval($r["cost"]);
					$cost *= floatval($tmp["count"]);
				}
			}
			$o = $this->__goRoundProdLevel($p, $outline.".".$out, $tmp);
			$cost += $o["cost"];
			$tmp->addAttribute("overal_cost", "". $cost);
			$ret["cost"] += $cost;
			$i++;
		}
		return $ret;
	}
	
	function __construct(ORMNaviFactory $factory, string $order_number, ?DateTime $deadline = null, ?string $customer_ref = null, ?string $prodmat_ref = null) {
		$this->factory = $factory;
		$this->number = $order_number;
		if (!$z = simplexml_load_file($this->factory->orders_dir . 'order-' . $this->number . '.xml')) {
			if (is_null($deadline)) throw new ORMNaviException("Deadline is mandatory parameter for new order");
			$c = $this->factory->getMDMCustomer($customer_ref);
			if (!$c) throw new ORMNaviException("Customer '".$customer_ref."' not found");
			$p = $this->factory->getProdmat($prodmat_ref);
			if (!$p) throw new ORMNaviException("Product '".$prodmat_ref."' not found");
			$z = new SimpleXMLElement("<order/>");
			$z->addAttribute("id", $order_number);
			$deadline->setTimezone($this->factory->timezone);
			$z->addAttribute("deadline", $deadline->format('Y-m-d H:i:s'));
			$c = $z->addChild("customer");
			$c->addAttribute("ref", $customer_ref);
			$outline = $order_number.".1.".$p["id"];
			$prtm = $c->addChild("product");
			$prtm->addAttribute("id", $outline);
			$prtm->addAttribute("ref", $p["ref"]);
			$o = $this->__goRoundProdLevel($p, $outline, $prtm);
			$prtm->addAttribute("overal_cost", $o["cost"]);
			$z->asXML($this->factory->orders_dir . 'order-' . $this->number . '.xml');
		}
		$this->xml = $z;
		$this->deadline = new DateTime($z["deadline"]);
		$sql = "call getOrder('".$this->factory->name."', '".$this->number."');";
		$x = $this->factory->dblink->query($sql);
		if (!$x) throw new ORMNaviException("Couldnot execute request ". $sql. ": " . $this->dblink->errno . " - " . $this->dblink->error);
		$y = $x->fetch_assoc();
		$x->free_result();
		$x = $this->factory->dblink->next_result();
		if ($y) {
			$this->_arrayImport($y);
		}
	}

	public function getEstimatedTime() {

	}
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

	protected function __routeProduct(SimpleXMLElement $routeRoot, SimpleXMLElement $orderProot, array $pathdict) {
		if ($orderProot->getName() == "workcenter") {
			if (is_null($routeRoot["workcenter"])) {
				$routeRoot->addAttribute("workcenter", $orderProot["ref"]);
			}
			return;
		}
		$subroute = $routeRoot->addChild($orderProot->getName());
		$subroute->addAttribute("ref", $orderProot["id"]);
		$subroute->addAttribute("refref", $orderProot["ref"]);
		if ($subroute->getName() == "operation") {
			$subroute->addAttribute("consumption", $orderProot["duration"]);
		}
		if ($subroute->getName() == "operation" && array_key_exists((string)$orderProot["id"], $pathdict)) {
			$subroute->addAttribute("workcenter", $pathdict[$orderProot["id"]]);
		}
		foreach ($orderProot as $el) {
			$this->__routeProduct($subroute, $el, $pathdict);
		}
	}

	protected function findForks(SimpleXMLElement $prodmat) {
		$forks = [];
		$x = $prodmat->xpath(".//operation/workcenter[2]/..");
		foreach ($x as $op) {
			$y = $op.xpath("workcenter");
			if (count($forks) > 0) {
				$temp = [];
				foreach ($forks as $f) {
					$i = 0;
					foreach($y as $wc) {
						if ($i != count($y) - 1) {
							$ndict = $f;
							$temp[] = $ndict;
						} else {
							$ndict = $f;
						}
						$ndict[$op["id"]] = $wc["ref"];
						$i++;
					}
				}
				foreach ($temp as $f) {
					$forks[] = $f;
				}
			} else {
				foreach ($y as $wc) {
					$ndict = [];
					$forks[] = $ndict;
					$ndict[$op["id"]] = $wc["ref"];
				}
			}
		}
		return $forks;
	}
	public function route() {
		$this->routes_xml = new SimpleXMLElement("<routes/>");
		$this->routes_xml->addAttribute("orderref", $this->number);
		$c = $this->xml->customer;
		$r = $this->factory->getRoadsTo($c["ref"]);
		if (!$r) {
			$r = $this->factory->getRoadsTo("customer*");
		}
		foreach ($r as $eroute) {
			foreach ($c->children() as $prodmat) {
				if ($prodmat->getName() == "product") {
					$fs = $this->findForks($prodmat);
					if (!$fs){
						$route = $this->routes_xml->addChild("route");
						$route->addAttribute("id", $this->number. "." . count($this->routes_xml->children()));
						$route->addAttribute("workcenter", $eroute["from"]);
						$this->__routeProduct($route, $prodmat, []);
					} else {
						foreach ($fs as $path) {
							$route = $this->routes_xml->addChild("route");
							$route->addAttribute("id", $this->number. "." . 1 + count($this->routes_xml->children()));
							$route->addAttribute("workcenter", $eroute["from"]);
							$this->__routeProduct($route, $prodmat, $path);
						}
					}
				}
				if ($prodmat->getName() == "material"){

				}
			}
		}
		$this->routes_xml->asXML($this->factory->routes_dir."route-".$this->number.".xml");
	}
}
class ORMNaviFactory {
    // factory mnemonic unique ID in this instance
	private $factory = "";
	// client ID one-to-one with factory.Filled from database. An ID in database
	private $user;
	// time zone for setting in database. Usually for client request. Helps to do no calculation on client  
	private $time_zone = null;
	// root folder of factory 
	private $data_dir = "";
	// relative path to orders' folder
	private $orders_dir = "";
	// relative path to the routes' folder
	private $routes_dir = "";
	// relative path to the products' folder
	private $product_dir = "";
	// loaded factory.xml in root folder
	private $factory_xml;
	private $mdm_xml;
	protected $dblink;
	function __construct(string $user, string $password, string $factory, ?DateTimeZone $time_zone = null) {
		$this->factory = $factory;
		$this->user = null;
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
		$this->mdm_xml = simplexml_load_file($this->data_dir . 'mdm.xml');
		if (!$this->mdm_xml) throw new ORMNaviException ("Wrong dictionary MDM XML: " . $this->data_dir . 'mdm.xml');
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
		$this->user = new ORMNaviUser($this, $user, $password);
		$this->user->authorize();
	}
	function __destruct() {
		$this->dblink->close();

	}
	function __get($name) {
		switch ($name) {
			case 'dblink':
				return $this->dblink;
				break;
			
			case 'orders_dir':
				return $this->orders_dir;
				break;

			case 'routes_dir':
				return $this->routes_dir;
				break;

				case 'name':
				return $this->factory;
				break;

			case 'timezone':
				return $this->time_zone;
				break;
			
			case 'user':
				return $this->user;
				break;
				
			default:
				# code...
				break;
		}
	}
	public function createOrder(string $order_number, string $customer_ref, DateTime $deadline ): ORMNaviOrder {

	}

	public function getOrder(string $order_number) :? ORMNaviOrder {

	}
	public function getMDMCustomer(string $customer_ref): SimpleXMLElement {
		$f = $this->mdm_xml->xpath("customer[@id='".$customer_ref."']");
		return $f[0];
	} 

	public function getMDMRef(string $ref) : SimpleXMLElement{
		$r = $this->mdm_xml->xpath("*[@id='" . $ref . "']");
		if (!$r) throw new ORMNaviException("Element by ref '".$ref."' isn't found in mdm.xml");
		if (count($r) > 1) throw new ORMNaviException("There are several elements by ref '".$ref."' in mdm.xml");
		return $r[0];
	}

	public function getWorkcentersOfOperation(string $ref) {
		$r = $this->factory_xml->xpath(".//operation[@ref='" . $ref . "']/..");
		if (!$r) throw new ORMNaviException("Couldn'n find workcenter for operation with id '".$ref."' in factory");
		return $r;
	}

	public function getProdmat($prodmat_ref) {
		$p = simplexml_load_file($this->product_dir."product-".$prodmat_ref.".xml");
		if (!$p || ($p->getName() != "product")) throw new ORMNaviException("Product xml must include root tag product");
		return $p;
	}

	public function getRoadsTo(string $ref) {
		$f = $this->factory_xml->xpath(".//road[@to='".$ref."']");
		return $f;
	}

	public function dismissMessage(int $message_id) {
		$sql = "call makeMessageRead(".$message_id.", '".$this->user->name."')";
	    $x = $this->dblink->query($sql);
	    if ($this->dblink->errno || !$x) throw new ORMNaviException("Could not create message: " . $this->dblink->errno . " - " . $this->dblink->error);
		$y = $x->fetch_assoc();
		$x->free_result();
		$this->dblink->next_result();
		return $y;
	}

	public function getIncomingMessages(bool $read = false, string $message_types = "") {
		$sql = "call getIncomingMessages('" . $this->name . "', '" . $this->user->name . "', '" . $this->user->subscriptionsForSearch . "', " . ($read?1:0) . ", '".$message_types."')";
	    $x = $this->dblink->query($sql);
	    if ($this->dblink->errno || !$x) throw new ORMNaviException("Could not get messages: " . $this->dblink->errno . " - " . $this->dblink->error);
		$ret = array();
		while ($y = $x->fetch_assoc()) {
			$m = ORMNaviMessage::createFromArray($this, $y);
			$ret[] = $m;
		}
		$x->free_result();
		$this->dblink->next_result();
		return $ret;
	}

}
?>