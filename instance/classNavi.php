<?php
opcache_reset();
//------------------
// naviClient class 
//
// 
class naviClient {
    const MESSAGE_INFO = 'INFO';
    const MESSAGE_WARNING = 'WARNING';
    const MESSAGE_CRITICAL = 'CRITICAL';

	private $factory = "";
	private $client_id = -1;
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
			if (array_key_exists("orders", $settings["dir"])) $this->orders_dir = $this->data_dir . $settings["dir"]["orders"];
			if (array_key_exists("routes", $settings["dir"])) $this->routes_dir = $this->data_dir . $settings["dir"]["routes"];
			if (array_key_exists("messages", $settings["dir"])) $this->message_dir = $this->data_dir . $settings["dir"]["messages"];
		}
		
		$this->factory_xml = simplexml_load_file($this->data_dir . 'factory.xml');
		if (!$this->factory_xml) throw new Exception ("Wrong factory XML: " . $this->data_dir . 'factory.xml');
		$found = $this->factory_xml->xpath("//user[@id='" . $_user . "']");
		if (!$found) throw new Exception ("User " . $_user . ' not found');
		$hash = md5($_user . $_password);
		if ((string) $found[0]["md5"] != $hash) throw new Exception ("Password incorrect! " . $hash);
//		var_dump($settings);
        $host = "";
        $database = "";
        $user = "";
        $password = "";
		
		if (array_key_exists("database", $settings)) {
			if (array_key_exists("host", $settings["database"])) $host = $settings["database"]["host"];
			if (array_key_exists("database", $settings["database"])) $database = $settings["database"]["database"];
			if (array_key_exists("user", $settings["database"])) $user = $settings["database"]["user"];
			if (array_key_exists("password", $settings["database"])) $password = $settings["database"]["password"];
		} else throw new Exception ("database settings are absent"); 
		
		$this->dblink = new mysqli($host, $user, $password, $database);
		if ($this->dblink->connect_errno) throw new Exception("Unable connect to database (" . $host . " - " . $database . "): " . $this->dblink->connect_errno . " - " . $this->dblink->connect_error);
		$this->dblink->set_charset("utf-8");
		$this->dblink->query("set names utf8");
		if (!is_null($this->time_zone)) $this->dblink->query("SET @@session.time_zone='" . ((0 < $this->time_zone)? "+":"") . $this->time_zone . ":00';");
		$x = $this->dblink->query("select getClientID('" . $this->factory . "') as client_id;");
		
		if (!$x) throw new Exception("Factory '" . $this->factory . "' not found in '" . $database. "': " . $this->dblink->errno . " - " . $this->dblink->error);
		$this->client_id = $x->fetch_assoc()["client_id"];
		$x->free_result();
	}
	function __destruct() {
		$this->dblink->close();
	}
	function getRoutes($_order) {
		if (!$z = simplexml_load_file($this->routes_dir . 'route-' . $_order . '.xml')) throw new Exception ("XML route-" . $_order . " is wrong!");
		$ret = array();
		foreach ($z as $res) $ret[] = ((array) $res->attributes())['@attributes'];
		return $ret;
	}
	function getRoute($_order, $_id) {
		if (!$z = simplexml_load_file($this->routes_dir . 'route-' . $_order . '.xml')) throw new Exception ("XML route-" . $_order . " is wrong! -- " . $this->routes_dir . 'route-' . $_order . '.xml');
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
	
	function getMessages($_tags, $_to, $_read) {
	    
	}
	
	function createMessage($_messageType) {
	}
	
	function _assignOrderRouteRecur($zz, $_order_id, $_route_id) {
	    if (count($zz->children()) == 0 && $zz->getName()=="operation" ) {
    		$x = $this->dblink->query("call assignWorkcenterToRoutePart(" . $this->client_id . ", '" . $_order_id . "', '" . $zz["ref"] . "', '" . $zz["workcenter"] . "', 'INCOME')");
    		if (!$x) throw new Exception("Unexpected error while setting mode" . "': " . $this->dblink->errno . " - " . $this->dblink->error . "call assignWorkcenterToRoutePart(" . $this->client_id . ", '" . $_order_id . "', '" . $zz["ref"] . "', '" . $zz["workcenter"] . "', 'INCOME')"); 
    		$x->free_result();
	    } else {
	        foreach ($zz as $zzz) {
	            $this->_assignOrderRouteRecur($zzz, $_order_id, $_route_id);
	        }
	    }
	    
	}
	
	function assignOrderRoute($_order, $_route_id) {
	    $this->dblink->autocommit(FALSE);
	    //echo $_order;
	    
	    $z = $this->getRoute($_order, $_route_id);
	    
        $x = $this->dblink->query("select addOrder(" . $this->client_id . ", '" . $_order . "', 'ASSIGNED') as order_id;");
		if (!$x) {
    	    $this->dblink->autocommit(TRUE);
		    throw new Exception("Unexpected error while adding order" . "': " . $this->dblink->errno . " - " . $this->dblink->error . "select addOrder(" . $this->client_id . ", '" . $_order . "', 'ASSIGNED') as order_id;");
		}
		$order_id = $x->fetch_assoc()["order_id"];
		//echo "order_id " . $order_id . "|||";
	    foreach ($z as $zz) {
	        $this->_assignOrderRouteRecur($zz, $order_id, $_route_id);
	    }
	    
		$this->dblink->query("call assignRouteToOrder(" . $this->client_id . ", '" . $_order . "', " . $_route_id . ");");
		
		if (!$this->dblink->commit()) {
    	    $this->dblink->autocommit(TRUE);
		    throw new Exception("Unexpected error while commit transaction" . "': " . $this->dblink->errno . " - " . $this->dblink->error);
		} 
	    $this->dblink->autocommit(TRUE);
	    $x->free_result();
	}
	
	function _drawRoad($_roadxml) {
		$ret = (object) [
			'html' => "",
			'script' => ""
		];
	    if ($_roadxml["from"] != "") {
    		$found_from = $this->factory_xml->xpath("//workcenter[@id='" . $_roadxml["from"] . "']");
    		if (!$found_from) return $ret; // throw new Exception ("Road " . $_roadxml["id"] . "referenced to nonexistent workcenter '" . $_roadxml["from"] . "'!");
	    }
	    if ($_roadxml["to"] != "") {
    		$found_to = $this->factory_xml->xpath("//workcenter[@id='" . $_roadxml["to"] . "']");
    		if (!$found_to) return $ret; //throw new Exception ("Road " . $_roadxml["id"] . "referenced to nonexistent workcenter '" . $_roadxml["to"] . "'!");
	    }
 	    $from_coords = explode(";", $found_from[0]["location"]);
	    $to_coords = explode(";", $found_to[0]["location"]);
	    $from_center = (object)['lat'=>(explode(",", $from_coords[1])[0] + explode(",", $from_coords[0])[0])/2, 'lng'=>(explode(",", $from_coords[1])[1] + explode(",", $from_coords[0])[1])/2];
	    $to_center = (object)['lat'=>(explode(",", $to_coords[1])[0] + explode(",", $to_coords[0])[0])/2, 'lng'=>(explode(",", $to_coords[1])[1] + explode(",", $to_coords[0])[1])/2];
	    
		$ret->html .= "<line id='" . $_roadxml['id'] . "' x1='0' y1='0' x2='0' y2='0' class='road' />";
		$ret->script .= "$('#" . $_roadxml['id'] . "').attr('x1', map.LAT2X(" . $from_center->lat . "));\n";
		$ret->script .= "$('#" . $_roadxml['id'] . "').attr('x2', map.LAT2X(" . $to_center->lat . "));\n";
		$ret->script .= "$('#" . $_roadxml['id'] . "').attr('y1', map.LNG2Y(" . $from_center->lng . "));\n";
		$ret->script .= "$('#" . $_roadxml['id'] . "').attr('y2', map.LNG2Y(" . $to_center->lng . "));\n"; 
		
		return $ret;
	}
	
	function _drawWorkcenter($_wcxml) {
		$ret = (object) [
			'html' => "",
			'script' => "",
		];
		$ret->html .= '<rect id="' . $_wcxml['id'] . '" width="0" height="0" data-toggle="tooltip" class="workcenter" title="' . trim((string) $_wcxml) . '"></rect>';
		$ret->html .= '<text id="' . $_wcxml['id'] . '_label" text-anchor="middle" x="0" y="0">' . trim((string) $_wcxml) . '</text>';
		if ($_wcxml['location'] != "") {
			$ret->script .= "loc = '" . $_wcxml['location'] . "'.split(';');\n";
			$ret->script .= "wcx = map.LAT2X(loc[0].split(',')[0]);\n";
			$ret->script .= "wcw = map.LAT2X(loc[1].split(',')[0]) - map.LAT2X(loc[0].split(',')[0]);\n";
			$ret->script .= "wcy = map.LNG2Y(loc[0].split(',')[1]);\n";
			$ret->script .= "wch = map.LNG2Y(loc[1].split(',')[1]) - map.LNG2Y(loc[0].split(',')[1]);\n";
			
			$ret->script .= "$('#" . $_wcxml['id'] . "').attr('x', wcx + 'px');\n";
			$ret->script .= "$('#" . $_wcxml['id'] . "').attr('y', wcy + 'px');\n";
			$ret->script .= "$('#" . $_wcxml['id'] . "').attr('width', wcw + 'px');\n";
			$ret->script .= "$('#" . $_wcxml['id'] . "').attr('height', wch + 'px');\n";

			$ret->script .= "$('#" . $_wcxml['id'] . "_label').attr('x', wcx + wcw/2 + 'px');\n";
			$ret->script .= "$('#" . $_wcxml['id'] . "_label').attr('y', wcy + wch/2 + 'px');\n";
			
			foreach ($_wcxml as $wc) {
				switch ( $wc->getName()	) {
					case "workcenter":
						$o = $this->_drawWorkcenter($wc);
						$ret->html .= $o->html;
						$ret->script .= $o->script;
						break;
				}
			}
		}
		return $ret;
	}
	
	function drawFactory() {
		$ret = (object) [
			'html' => '<svg  width="100%" height="100%">',
			'script' => "",
		];
		foreach ($this->factory_xml as $wc) {
			switch ( $wc->getName()	) {
				case "workcenter":
					$o = $this->_drawWorkcenter($wc);
					$ret->html .= $o->html;
					$ret->script .= $o->script;
					break;
				case "road":
					$o = $this->_drawRoad($wc);
					$ret->html .= $o->html;
					$ret->script .= $o->script;
					break;
				case "operation":
					break;
				case "user":
					break;
				default:
					throw new Exception ("Unexpected tag " . $wc->getName() . " in factory");
			}
		} 
		$ret->html .= '</svg>';
		return $ret;
	}
	function getWorkcenterAssigns($_wc){
	    $x = $this->dblink->query("call getBuckets(1);");
		if (!$x) throw new Exception("Could not get buckets" . "': " . $this->dblink->errno . " - " . $this->dblink->error . "call getBuckets(1);"); 	    
	    $ret = [];
	    $bucks = "";
	    while ($y = $x->fetch_assoc()) {
	        if (strlen($bucks)) $bucks .= ",";
	        $bucks .= $y["bucket"];
	        $ret[$y["bucket"]] = [];
	    }
	    $x->free_result();
	    $this->dblink->next_result();
	    //echo "call getAssignsByWorkcenter(" . $this->client_id . ", '" . $_wc . "', '" . $bucks . "');";
	    
        $a = $this->dblink->query("call getAssignsByWorkcenter(" . $this->client_id . ", '" . $_wc . "', '" . $bucks . "');");

        
        if (!$a) throw new Exception("Could not get assigns by workcenter" . "': " . $this->dblink->errno . " - " . $this->dblink->error . "call getAssignsByWorkcenter(" . $this->client_id . ", '" . $_wc . "', '" . $bucks . "');"); 
	    while ($z = $a->fetch_assoc()) {
	        $ret[$z["bucket"]][] = $z;
	        //var_dump($z);
	    }
	    $a->free_result();
		return $ret;
	}
	
	function getWorkcenterInfo($_wc){
		$found = $this->factory_xml->xpath("//workcenter[@id='" . $_wc . "']");
		//var_dump($found);
		if (!$found)  throw new Exception ("workcenter " . $_wc . " not found!");
		return $found[0];
	}
}
?>