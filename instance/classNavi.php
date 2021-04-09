<?php
//opcache_reset();
error_reporting(-1);
ini_set('display_errors', 'On');
//------------------
// naviClient class 
//
// 
class naviClient {
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
	
	private $message_dir = "";
	// loaded factory.xml in root folder
	private $factory_xml;
	
	
	function __construct(string $_user, string $_password, string $_factory, ?int $_time_zone = null) {
		$this->factory = $_factory;
		$this->user = $_user;
		$this->time_zone = $_time_zone;
		// set root folder
		$this->data_dir = "../" . $this->factory . "-data/";
		// finding and parsing  settings.ini for database settings & folders settings
		$settings = parse_ini_file($this->data_dir . "settings.ini", true);
		if (array_key_exists("dir", $settings)) {
			if (array_key_exists("products", $settings["dir"])) $this->product_dir = $this->data_dir . $settings["dir"]["products"];
			if (array_key_exists("orders", $settings["dir"])) $this->orders_dir = $this->data_dir . $settings["dir"]["orders"];
			if (array_key_exists("routes", $settings["dir"])) $this->routes_dir = $this->data_dir . $settings["dir"]["routes"];
			if (array_key_exists("messages", $settings["dir"])) $this->message_dir = $this->data_dir . $settings["dir"]["messages"];
		}
		// loading factory.xml
		$this->factory_xml = simplexml_load_file($this->data_dir . 'factory.xml');
		if (!$this->factory_xml) throw new Exception ("Wrong factory XML: " . $this->data_dir . 'factory.xml');
		$found = $this->factory_xml->xpath("//user[@id='" . $_user . "']");
		if (!$found) throw new Exception ("User " . $_user . ' not found');
		//checking md5 user hash
		$hash = md5($_user . $_password);
		if ((string) $found[0]["md5"] != $hash) throw new Exception ("Password incorrect! " . $hash);
//		var_dump($settings);
        // connecting to database
        $host = "localhost";
        $database = "nppc";
        $user = "";
        $password = "";
		$port = "3306";
		
		if (array_key_exists("database", $settings)) {
			if (array_key_exists("host", $settings["database"])) $host = $settings["database"]["host"];
			if (array_key_exists("database", $settings["database"])) $database = $settings["database"]["database"];
			if (array_key_exists("user", $settings["database"])) $user = $settings["database"]["user"];
			if (array_key_exists("password", $settings["database"])) $password = $settings["database"]["password"];
			if (array_key_exists("port", $settings["database"])) $port = $settings["database"]["port"];
		} else throw new Exception ("database settings are absent"); 
		
		$this->dblink = new mysqli($host, $user, $password, $database, $port);
		if ($this->dblink->connect_errno) throw new Exception("Unable connect to database (" . $host . " - " . $database . " - port ".$port."): " . $this->dblink->connect_errno . " - " . $this->dblink->connect_error);
		$this->dblink->set_charset("utf-8");
		$this->dblink->query("set names utf8");
		if (!is_null($this->time_zone)) $this->dblink->query("SET @@session.time_zone='" . ((0 < $this->time_zone)? "+":"") . $this->time_zone . ":00';");
		// loading client ID
		$x = $this->dblink->query("select getClientID('" . $this->factory . "') as client_id;");
		
		if (!$x) throw new Exception("Factory '" . $this->factory . "' not found in '" . $database. "': " . $this->dblink->errno . " - " . $this->dblink->error);
		$this->client_id = $x->fetch_assoc()["client_id"];
		$x->free_result();
		
		$this->user_id = $this->getUserIDByName($this->user);
	}
	
	function __destruct() {
		$this->dblink->close();
	}
	
	function getUserIDByName(string $_name) {
		$x = $this->dblink->query("select getUserID(" . $this->client_id . ", '" . $this->user . "') as user_id;");
		if (!$x) throw new Exception("User '" . $this->user . "' not found in database. : " . $this->dblink->errno . " - " . $this->dblink->error);
		$user_id = $x->fetch_assoc()["user_id"];
		$x->free_result();
		return $user_id;
	}
	
	// getRoutes loads route-*.xml by the order's number
	// $_order is a string as the order's number
	// getRoutes returns content route-*.xml as php object
	function getRoutes($_order) {
		if (!$z = simplexml_load_file($this->routes_dir . 'route-' . $_order . '.xml')) throw new Exception ("XML route-" . $_order . " is wrong!");
		$ret = array();
		foreach ($z as $res) $ret[] = ((array) $res->attributes())['@attributes'];
		return $ret;
	}
	
	// getOrder loads order-*.xml by the order's number
	// $_order is a string as the order's number
	// getOrder returns content order-*.xml as php object
	function getOrder($_order) {
		if (!$z = simplexml_load_file($this->orders_dir . 'order-' . $_order . '.xml')) throw new Exception ("XML order-" . $_order . " is wrong!");
		return $z;
	}

	// getRoute loads route-*.xml by the order's number
	// $_order is a string as the order's number
	// $_id is a integer id of choosen route in routes file
	// getRoute returns content of route with ID as php object
	function getRoute($_order, $_id) {
		if (!$z = simplexml_load_file($this->routes_dir . 'route-' . $_order . '.xml')) throw new Exception ("XML route-" . $_order . " is wrong! -- " . $this->routes_dir . 'route-' . $_order . '.xml');
		$found = $z->xpath("//route[@id='" . $_order . "." . $_id . "']");
		if (!$found)  throw new Exception ("Route " . $_order . "." . $_id . " not found!");
		return $found[0];
	}
	
	// some properties of class
	// property factoryMap is a string as rectangle in world geo position formed as left,top;right,bottom
	// property factoryName is not mnemonic ID. It's a long name for brand label
	// property factorySatellite is a relative path to a background image
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
	
	// 
	function getMessages($_tags = "", $_to = 0, $_read = 0, $_types = "") {
	    if ($_to == 0) $_to = $this->user_id;
		$x = $this->dblink->query("call getMessages(" . $this->client_id . ", '" . $_tags . "', " . $_to . ", " . $_read . ", '" . $_types . "')");
		if (!$x) throw new Exception("Unexpected error while getting messages" . ": " . $this->dblink->errno . " - " . $this->dblink->error . " call getMessages(" . $this->client_id . ", '" . $_tags . "', '" . $_to . "', " . $_read . ", '" . $_types . "')"); 
		$ret = array();
		while ($res = $x->fetch_assoc()) $ret[] = $res;
		$x->free_result();	
		return $ret;
    }
	
	//
	function createMessage(string $_body, ?int $_order_id = 0, ?int $_to = 0, string $_messageType = "primary", int $_reply = 0) {
	    $this->dblink->query("select addMessage(" . $this->client_id . ", " . (is_null($_order_id)?0 : $_order_id) . ", " . $this->user_id . ", " . $_to . ", '" . $_messageType . "', '" . $_body . "', " . $_reply . ")");
	    if ($this->dblink->errno) throw new Exception("Could not create message: " . $this->dblink->errno . " - " . $this->dblink->error);
	}

	// recursive ancillary function for assigning orders route to workcenters
	// $zz is xml struct 
	// $_order_id is uniq ID from database
	// $_route_id is ID in route-*.xml
	function _assignOrderRouteRecur($zz, $_order_id, $_route_id) {
	    //var_dump($zz);
	    if (count($zz->children()) == 0 && $zz->getName()=="operation" ) {
    	    //var_dump($zz);

    		$x = $this->dblink->query("call assignWorkcenterToRoutePart(" . $this->client_id . ", '" . $_order_id . "', '" . $zz["ref"] . "', '" . $zz["refref"] . "', '" . $zz["workcenter"] . "', 'INCOME', " . $zz["consumption"] . ")");
    		if (!$x) {
    		    $this->dblink->rollback();
        	    $this->dblink->autocommit(TRUE);
    		    throw new Exception("Unexpected error while setting mode" . "': " . $this->dblink->errno . " - " . $this->dblink->error . "call assignWorkcenterToRoutePart(" . $this->client_id . ", '" . $_order_id . "', '" . $zz["ref"] . "', '" . $zz["refref"] . "', '" . $zz["workcenter"] . "', 'INCOME', " . $zz["consumption"] . ")"); 
    		}
    		//$x->free_result();
	    } else {
	        foreach ($zz as $zzz) {
	            $this->_assignOrderRouteRecur($zzz, $_order_id, $_route_id);
	        }
	    }
	    
	}
	
	// assignOrderRoute assigns route of order to workcenters
	// $_order is a string of the order's number
	// $_route_id is a number of route from available set of routes
	function assignOrderRoute($_order, $_route_id) {
	    $this->dblink->autocommit(FALSE);
	    //echo $_order;
	    
	    $o = $this->getOrder($_order);
	    $z = $this->getRoute($_order, $_route_id);
	    
        $x = $this->dblink->query("select addOrder(" . $this->client_id . ", '" . $_order . "', 'ASSIGNED', " . $_route_id . ", '" . $o["deadline"] . "') as order_id;");
		if (!$x) {
		    $this->dblink->rollback();
    	    $this->dblink->autocommit(TRUE);
		    throw new Exception("Unexpected error while adding order" . "': " . $this->dblink->errno . " - " . $this->dblink->error . "select addOrder(" . $this->client_id . ", '" . $_order . "', 'ASSIGNED', " . $_route_id . ") as order_id;");
		}
		$order_id = $x->fetch_assoc()["order_id"];
	    foreach ($z as $zz) {
	        $this->_assignOrderRouteRecur($zz, $order_id, $_route_id);
	    }
	    
/*		$this->dblink->query("call assignRouteToOrder(" . $this->client_id . ", '" . $_order . "', " . $_route_id . ");");
		if ($this->dblink->errno) {
		    $this->dblink->rollback();
    	    $this->dblink->autocommit(TRUE);
		    throw new Exception("Unexpected error while assign order" . "': " . $this->dblink->errno . " - " . $this->dblink->error . "call assignRouteToOrder(" . $this->client_id . ", '" . $_order . "', " . $_route_id . ");");
		}
*/		
		$c = $this->calcOrderEstimatedTime($_order);
		$fet = new DateTime();
		$fet->setTimezone(new DateTimeZone(sprintf("%+'.03d:00", $this->time_zone)));
		$fet->modify("+" . $c . " minutes");
		$this->dblink->query("call updateBaseline(" . $order_id . ", '" . $fet->format('Y-m-d H:i:s') . "');");
		if ($this->dblink->errno) {
		    $this->dblink->rollback();
    	    $this->dblink->autocommit(TRUE);
		    throw new Exception("Unexpected error while assign order" . "': " . $this->dblink->errno . " - " . $this->dblink->error . "call updateBaseline(" . $order_id . ", '" . $fet->format('Y-m-d H:i:s') . "');");
		}
		
		if (!$this->dblink->commit()) {
    	    $this->dblink->autocommit(TRUE);
		    throw new Exception("Unexpected error while commit transaction" . "': " . $this->dblink->errno . " - " . $this->dblink->error);
		} 
	    $this->dblink->autocommit(TRUE);
	    $x->free_result();
	    return $order_id;
	}
	
	// moveAssignToNextBucket slides order part forward
	// $_assign_id is a uniq ID from database
	function moveAssignToNextBucket($_assign_id) {
	    $this->dblink->autocommit(FALSE);
		$x = $this->dblink->query("call moveAssignToNextBucket(" . $_assign_id . ");");
		if (!$x) {
		    $this->dblink->rollback();
    	    $this->dblink->autocommit(TRUE);
		    throw new Exception("Unexpected error while move Assign to next bucket" . "': " . $this->dblink->errno . " - " . $this->dblink->error . "select moveAssignToNextBucket(" . $_assign_id . ") as newbucket;");
		}
		$x = $x->fetch_assoc();
		$this->dblink->next_result();
		$nextbucket = $x["next_bucket"];
		$ordernum = $x["order_num"];
		$order_id = $x["order_id"];
		if ('' == $nextbucket) {
		    $this->dblink->rollback();
    	    $this->dblink->autocommit(TRUE);
		    throw new Exception("Got empty next bucket. ASSIGN_ID=" . $_assign_id);
		}
		// if order_part has processed, must update by route tree into new part
		    //we have to update order_part and look for next workcenter according with current route
		if ('OUTCOME' == $nextbucket) {
		    $z = $this->getRoute($x["order_num"], $x["route_num"]);
		    $found = $z->xpath("//operation[@ref='" . $x["order_part"] . "']/..");
		    //var_dump($found);
		    if (!$found) {
    		    $this->dblink->rollback();
        	    $this->dblink->autocommit(TRUE);
		        throw new Exception("Order num = " . $x["order_num"] . ". Route num = " . $x["route_num"] . ". Product part = " . $x["order_part"] . ". Assign width id = " . $_assign_id . " needs to update route");
		        
		    }
		    $readyorderpart = (string)$found[0]["ref"];
		    
		    while ((string)$found[0]["workcenter"]=='' and $found[0]->getName() != 'route') {
		        $found = $z->xpath("//*[@ref='" . $found[0]["ref"] . "']/..");
    		    //var_dump((string)$found[0]["workcenter"]);
		    }
		    $nextworkcenter = (string)$found[0]["workcenter"];
		    $nextoperation = (string)$found[0]["refref"];
		    if ($found[0]->getName() == 'route') $nextorderpart = "";
		    else $nextorderpart = (string)$found[0]["ref"];
		    //var_dump($nextworkcenter);
		    //var_dump($nextorderpart);
		    //var_dump($readyorderpart);
		    //echo "call updateAssignOrderPart(" . $_assign_id . ", '" . $readyorderpart . "', '" . $nextworkcenter . "', '" . $nextorderpart . "', '" . $nextoperation . "')')";

	        $this->dblink->query("call updateAssignOrderPart(" . $_assign_id . ", '" . $readyorderpart . "', '" . $nextworkcenter . "', '" . $nextorderpart . "', '" . $nextoperation . "', " . $found[0]["consumption"] . ")");
	        if ($this->dblink->errno) {
		        throw new Exception("Unexpected error while update Assign to OUTCOME bucket" . "': " . $this->dblink->errno . " - " . $this->dblink->error . "call updateAssignOrderPart(" . $_assign_id . ", '" . $readyorderpart . "', '" . $nextworkcenter . "', '" . $nextorderpart . "', '" . $nextoperation . "')");
            }
	        
	        $msg = $this->dblink->escape_string("Order '" . $ordernum . "' processed '" . $x["operation"] . "' and ready to next workcenter '" . $nextworkcenter . "'");
		    //!!!we have to get new label for newborn part
		}
		if (!$this->dblink->commit()) {
    	    $this->dblink->autocommit(TRUE);
		    throw new Exception("Unexpected error while commit transaction" . "': " . $this->dblink->errno . " - " . $this->dblink->error);
		} 
	    $this->dblink->autocommit(TRUE);
	    
	    if (isset($msg)) $this->createMessage($msg, $order_id);
	}
	
	function moveAssignToNextWorkcenter($_assign_id) {
	    $x = $this->dblink->query("call getAssignInfo(" . $_assign_id . ");");
		if (!$x) throw new Exception("Could not get assign info" . "': " . $this->dblink->errno . " - " . $this->dblink->error . "call getAssignInfo(" . $_assign_id . ");");
		$res = $x->fetch_assoc();
        //var_dump($res);
        $ordernum = (string)$res["number"];
        $route_id = (string)$res["current_route"];
        $nextorderpart = (string)$res["next_order_part"];
        $x->free_result();
        $this->dblink->next_result();
        $r = $this->getRoute($ordernum, $route_id);
        $found = $r->xpath("//operation[@ref='" . $nextorderpart . "']");
        //var_dump($found);
        //echo $found[0]->count();
		$x = $this->dblink->query("call moveAssignToNextWorkcenter(" . $_assign_id . ", " . $found[0]->count() . ");");
		if ($this->dblink->errno) {
		    throw new Exception("Unexpected error while move Assign to next workcenter" . "': " . $this->dblink->errno . " - " . $this->dblink->error . "call moveAssignToNextWorkcenter(" . $_assign_id . ");");
		}
	}
	
	// _drawRoad is  ancillary function for drawing factory schema
	// $_roadxml is xml node from factory.xml
	function _drawRoad($_roadxml, $_rload) {
		$ret = (object) [
			'html' => "",
			'script' => ""
		];
		$c_max = floatval($_roadxml["capacity"]);
		
	    if ($_roadxml["from"] != "") {
    		$found_from = $this->factory_xml->xpath("//workcenter[@id='" . $_roadxml["from"] . "']");
    		if (!$found_from) return $ret; // throw new Exception ("Road " . $_roadxml["id"] . "referenced to nonexistent workcenter '" . $_roadxml["from"] . "'!");
	    }
	    if ($_roadxml["to"] != "") {
    		$found_to = $this->factory_xml->xpath("//workcenter[@id='" . $_roadxml["to"] . "']");
    		if (!$found_to) return $ret; //throw new Exception ("Road " . $_roadxml["id"] . "referenced to nonexistent workcenter '" . $_roadxml["to"] . "'!");
	    }
	    $c = 0;
	    $c_index = (string)$_roadxml["id"];
	    if (array_key_exists($c_index, $_rload)) $c = $_rload[$c_index];
	    $cc = 11;
	    if ($c < $c_max) $cc = round($c/$c_max * 12);
	    if (!$c) $cc = -1;
 	    $from_coords = explode(";", $found_from[0]["location"]);
	    $to_coords = explode(";", $found_to[0]["location"]);
	    $from_center = (object)['lat'=>(explode(",", $from_coords[1])[0] + explode(",", $from_coords[0])[0])/2, 'lng'=>(explode(",", $from_coords[1])[1] + explode(",", $from_coords[0])[1])/2];
	    $to_center = (object)['lat'=>(explode(",", $to_coords[1])[0] + explode(",", $to_coords[0])[0])/2, 'lng'=>(explode(",", $to_coords[1])[1] + explode(",", $to_coords[0])[1])/2];
	    
		$ret->html .= "<line id='" . $_roadxml['id'] . "' x1='0' y1='0' x2='0' y2='0' class='road" . (($cc < 0)? " noduty":" duty-" . $cc)  . "' road='".$_roadxml['id']."'/>";
		$ret->script .= "$('#" . $_roadxml['id'] . "').attr('x1', map.LAT2X(" . $from_center->lat . "));\n";
		$ret->script .= "$('#" . $_roadxml['id'] . "').attr('x2', map.LAT2X(" . $to_center->lat . "));\n";
		$ret->script .= "$('#" . $_roadxml['id'] . "').attr('y1', map.LNG2Y(" . $from_center->lng . "));\n";
		$ret->script .= "$('#" . $_roadxml['id'] . "').attr('y2', map.LNG2Y(" . $to_center->lng . "));\n"; 
		
		return $ret;
	}
	
	// _drawWorkcenter is ancillary recursive function for drawing factory
	// $_wcxml is node
	// $_wloads is information about workload of that Worcenter for calculation colour of one
	function _drawWorkcenter($_wcxml, $_wloads) {
		$ret = (object) [
			'html' => "",
			'script' => "",
		];
		//calculating workload colour of rect
		$found = $_wcxml->xpath("operation");
		if (!$found) throw new Exception ("Worcenter can't determine workload 'cause it has no the operations");
		//var_dump($found);
		// calculating color of workcenter
		$cc = 0;
		$i = 0;
		$ttip = "";
		//var_dump($_wloads);
		foreach ($found as $f) {
		    if (array_key_exists((string)$_wcxml['id'] . "_" . $f["ref"], $_wloads)) {
    		    $c = floatval($_wloads[(string)$_wcxml['id'] . "_" . $f["ref"]]["assings_count"]);
		    } else $c = 0;
    		$c_max = floatval($f['capacity']);
    		$ttip .= $f["ref"] . ": " . $c . " orders in queue. Capacity: " . $c_max . "\n";
    		$cc += $c / $c_max ;
    		$i++;
		}
		$cc /= $i;
		if ($cc >= 1) $cc = 11;
		elseif ($cc > 0) $cc = round($cc * 12);
		else $cc = -1;
		//echo($_wcxml['id'] . " " . (($cc < 0)? "":" duty-" . $cc));
		
		//var_dump($_wcxml);
		$ret->html .= '<rect id="' . $_wcxml['id'] . '" width="0" height="0" data-toggle="tooltip" class="workcenter' . (($cc < 0)? " noduty":" duty-" . $cc) . '" title="' . trim((string) $ttip) . '" workcenter="'.$_wcxml['id'].'"></rect>';
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
						$o = $this->_drawWorkcenter($wc, $_wloads);
						$ret->html .= $o->html;
						$ret->script .= $o->script;
						break;
				}
			}
		}
		return $ret;
	}
	
	// drawFactory draws all workcenters and roads with colorised and tooltips
	// function returns an object consist of html and script
	function drawFactory() {
	    // loading curren workload of workcenters
	    $x = $this->dblink->query("call getAssignsCount(" . $this->client_id . ", 'INCOME,PROCESSING');");
		if (!$x) throw new Exception("Could not get count of assigns in workcenters" . "': " . $this->dblink->errno . " - " . $this->dblink->error . "call getAssignsCount(" . $this->client_id . ", 'INCOME,PROCESSING');");
		$workloads = array();
		while ($res = $x->fetch_assoc()) $workloads[$res["name"] . "_" . $res["operation"]] = $res;
		//var_dump($workloads);
		$x->free_result();
        $this->dblink->next_result();
        
	    // loading current workload of roads 
	    $x = $this->dblink->query("call getRoadsWorkload('" . $this->factory . "');");
		if (!$x) throw new Exception("Could not get count of ready to road" . "': " . $this->dblink->errno . " - " . $this->dblink->error . "ccall getRoadsWorkload(" . $this->client_id . ");");
		$roadloads = array();
		while ($res = $x->fetch_assoc()) $roadloads[$res["name"]] = $res["delivery_count"];
		//var_dump($roadloads);
		
		$ret = (object) [
			'html' => '<svg  width="100%" height="100%">',
			'script' => "",
		];
		foreach ($this->factory_xml as $wc) {
			switch ( $wc->getName()	) {
				case "workcenter":
					$o = $this->_drawWorkcenter($wc, $workloads);
					$ret->html .= $o->html;
					$ret->script .= $o->script;
					break;
				case "road":
					$o = $this->_drawRoad($wc, $roadloads);
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
	
	// returns all assigns of workcenters by buckets
	// $_wc is a string uniq ID from factory.xml
	// returns object struct with data
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
	
	function getRoadAssigns($_wc_from, $_wc_to) {
	    $ret = [];
	    $ret[$_wc_from] = [];
	    $ret[$_wc_to] = [];
        $a = $this->dblink->query("call getAssignsByRoads(" . $this->client_id . ", '" . $_wc_from . "', '" . $_wc_to . "');");
        if (!$a) throw new Exception("Could not get assigns by workcenter" . "': " . $this->dblink->errno . " - " . $this->dblink->error . "call getAssignsByRoad(" . $this->client_id . ", '" . $_wc_from . "', '" . $_wc_to . "');"); 
	    while ($z = $a->fetch_assoc()) {
	        $ret[$_wc_from][] = $z;
	    }
	    $a->free_result();
	    $this->dblink->next_result();
	    
        $a = $this->dblink->query("call getAssignsByWorkcenter(" . $this->client_id . ", '" . $_wc_to . "', 'INCOME');");
        if (!$a) throw new Exception("Could not get assigns by workcenter" . "': " . $this->dblink->errno . " - " . $this->dblink->error . "call getAssignsByWorkcenter(" . $this->client_id . ", '" . $_wc_to . "', 'INCOME');"); 
	    while ($z = $a->fetch_assoc()) {
	        $ret[$_wc_to][] = $z;
	    }
	    $a->free_result();	    
		return $ret;
	}
	
	// returns xml node of workcenter from factory.xml
	function getWorkcenterInfo($_wc){
		$found = $this->factory_xml->xpath("//workcenter[@id='" . $_wc . "']");
		//var_dump($found);
		if (!$found)  throw new Exception ("workcenter " . $_wc . " not found!");
		return $found[0];
	}

	// returns xml node of road from factory.xml
	function getRoadInfo($_road){
		$found = $this->factory_xml->xpath("//road[@id='" . $_road . "']");
		//var_dump($found);
		if (!$found)  throw new Exception ("Road " . $_road . " not found!");
		return $found[0];
	}
	
	function getOrderInfo($_order_num) {
        $x = $this->dblink->query("call getOrderInfo(" . $this->client_id . ", '" . $_order_num . "');");
        if (!$x) throw new Exception("Could not get order info" . "': " . $this->dblink->errno . " - " . $this->dblink->error . "call getOrderInfo(" . $this->client_id . ", '" . $_order_num . "');"); 
        $z = $x->fetch_assoc();
        
        if (!$z) throw new Exception("Order " . $_order_num . " not found in database: "); 
        $o = $this->getOrder($_order_num);
        $r = $this->getRoute($_order_num, $z["current_route"]);
        $x->free_result();
        $this->dblink->next_result();
        $x = $this->dblink->query("call getOrderHistory(" . $z["id"] . ")");
        
        if (!$x) throw new Exception("Could not get order history info" . "': " . $this->dblink->errno . " - " . $this->dblink->error . "call getOrderHistory(" . $z["id"] . ")"); 
        $a = [];
        while ($y = $x->fetch_assoc()) {
            $a[] = $y;
            //var_dump($a);
        }
        //var_dump($z["id"]);
        $ret = [];
        $ret["db"] = $z;
        $ret["route"] = $r;
        $ret["order"] = $o;
        $ret["assigns"] = $a;
        $x->free_result();
        $this->dblink->next_result();
        return $ret;
    }
    function makeMessageRead($_messageID) {
        $this->dblink->query("call makeMessageRead(" . $_messageID . ", " . $this->user_id . ")");
        if ($this->dblink->errno) {
	        throw new Exception("Unexpected error while make message read" . "': " . $this->dblink->errno . " - " . $this->dblink->error . "call makeMessageRead(" . $_messageID . ", " . $this->user_id . ")");
        }
    }
    
    function getOrdersForImport() {
        $ret = [];
        $ret["to_import"] = [];
        $ret["imported"] = [];
        //reading orders from folder
        $fd = scandir($this->orders_dir);
        $fd = array_filter($fd, function ($v, $k) {
            return fnmatch("order-*.xml", $v);
            
        }, ARRAY_FILTER_USE_BOTH);
        foreach ($fd as $k => $fn) {
            $order_num = substr($fn, 6, strlen($fn) - 8 - strrpos($fn, ".xml"));
            $x = $this->getOrder($order_num);
            $v = (string)$x["deadline"];
            $ret["to_import"][$order_num] = $v;
        }
        asort($ret["to_import"]);
        
        //var_dump($ret["to_import"]);

        // reading orders from database
        $x = $this->dblink->query("call getOrders(" . $this->client_id . ")");
        
        if (!$x) throw new Exception("Could not get order's list" . "': " . $this->dblink->errno . " - " . $this->dblink->error . "call getOrders(" . $this->client_id . ")"); 
        while ($y = $x->fetch_assoc()) {
            $ret["imported"][] = $y;
            // checking order being able to import
            if (array_key_exists($y["number"], $ret["to_import"])) unset($ret["to_import"][$y["number"]]);
            //var_dump($a);
        }
        $x->free_result();
        $this->dblink->next_result();
        
        return $ret;
    }
    function _checkEstimatedTime($route_root, &$full_order_info) {
        //searching in assigns
        
        switch ($route_root->getName()){
             case "operation": 
                // looking for order part at workcenter
                $found = FALSE;
                foreach ($full_order_info["assigns"] as $wcp) {
                    if ($wcp["order_part"] == $route_root["ref"]) {
                        $found = TRUE;
                        //var_dump($route_root->getName());
                        //var_dump((string)$route_root["ref"]);
                        //var_dump(floatval($route_root["consumption"]));
                        //var_dump((string)$wcp["id"]);
                        //var_dump((string)$wcp["workcenter_id"]);
                        //getting worcenter workload
                	    $this->dblink->next_result();
                        $x = $this->dblink->query("select getAssignConsumptionInWorkcenter(" . $wcp["id"] . ") as consumption");
                        
                        if (!$x) throw new Exception("Could not get time consumption" . "': " . $this->dblink->errno . " - " . $this->dblink->error . " select getAssignConsumptionInWorkcenter(" . $wcp["id"] . ") as consumption"); 
                        $y = $x->fetch_assoc(); 
                        $x->free_result();
            
                        return floatval($y["consumption"]);
                        break;
                    }
                }
                break;
            
            default:
                break;
        }
        $max_c = 0.0;
        foreach ($route_root as $c) {
            $csp = $this->_checkEstimatedTime($c, $full_order_info);
            if ($csp > $max_c) $max_c = $csp;
        }
        $c = 0;
        if (!is_null($route_root["workcenter"])) {
            //var_dump($full_order_info["db"]["id"]);
    	    $this->dblink->next_result();
            $x = $this->dblink->query("select getOrderConsumptionInWorkcenter(" . $full_order_info["db"]["id"] . ", '" . $route_root["workcenter"] . "') as consumption");
            if (!$x) throw new Exception("Could not get time consumption" . "': " . $this->dblink->errno . " - " . $this->dblink->error . " select getOrderConsumptionInWorkcenter(" . $full_order_info["db"]["id"] . ", '" . $route_root["workcenter"] . "') as consumption;"); 
            $y = $x->fetch_assoc(); 
            $c = $y["consumption"];
            $x->free_result();
        }
                        
        //var_dump($c);
        
        return $max_c + $c + floatval($route_root["consumption"]);
    }
    
    function calcOrderEstimatedTime($order_num) {
        //var_dump($order_num);
        $fullorderinfo = $this->getOrderInfo($order_num);
        //var_dump($fullorderinfo["assigns"]);
        return $this->_checkEstimatedTime($fullorderinfo["route"], $fullorderinfo);
    }
    
    function updateEstimatedTime($fullorderinfo) {
        $c = $this->_checkEstimatedTime($fullorderinfo["route"], $fullorderinfo);
        
		$fet = new DateTime();
		$fet->setTimezone(new DateTimeZone(sprintf("%+'.03d:00", $this->time_zone)));
		$fet->modify("+" . $c . " minutes");
		$this->dblink->query("call updateEstimatedTime(" . $fullorderinfo["db"]["id"] . ", '" . $fet->format('Y-m-d H:i:s') . "');");
		if ($this->dblink->errno) {
		    throw new Exception("Unexpected error while update estimated time order" . "': " . $this->dblink->errno . " - " . $this->dblink->error . "call updateEstimatedTime(" . $fullorderinfo["db"]["id"] . ", '" . $fet->format('Y-m-d H:i:s') . "');");
		}
        $this->dblink->next_result();
	}
	
	function getUserByLetters(string $letters) {
		$found = $this->factory_xml->xpath("//user[starts-with(@id, '" . $letters . "')]");
//		$found = $this->factory_xml->xpath("//user[contains(lower-case(@id), '" . strtolower($letters) . "')]");
        $ret = [];
        foreach($found as $f) {
            $ret[] = (string)$f["id"];
        }
		return $ret;
	}
}
?>