<?php
function diffstr( $a,  $b) {
    $ret = [];
    if (is_null($a) || is_null($b)) return $ret;
    $interval = $a->diff($b);
    $dstr = "";
    if ($interval->y) $dstr .= $interval->y . "y";
    elseif ($interval->m) $dstr .= $interval->m . "mo";
    elseif ($interval->days) $dstr .= $interval->days . "d";
    elseif ($interval->h) $dstr .= $interval->h . "h";
    elseif ($interval->i) $dstr .= $interval->m . "mi";
    if ($interval->invert) $ret["lag"] = "-" . $dstr;
    else $ret["advance"] = "+" . $dstr;
    return $ret;
}
function order_db_string($_order_data) {
    $td = new DateTime();
    $orderdeadline = $_order_data["deadline"]?new DateTime($_order_data["deadline"]):null;
    $orderbaseline = $_order_data["baseline"]?new DateTime($_order_data["baseline"]):null;
    $orderestimated = $_order_data["estimated"]?new DateTime($_order_data["estimated"]):null;
    $ds = diffstr($orderbaseline, $orderdeadline);
    if (isset($ds["lag"])) $lagdeadbasestr = $ds["lag"];
    if (isset($ds["advance"])) $advancedeadbasestr = $ds["advance"];

    $ds = diffstr($orderestimated, $orderbaseline);
    if (isset($ds["lag"])) $lagbaseeststr = $ds["lag"];
    if (isset($ds["advance"])) $advancebaseeststr = $ds["advance"];

    $ds = diffstr($orderestimated, $orderdeadline);
    if (isset($ds["lag"])) $lagdeadeststr = $ds["lag"];
    if (isset($ds["advance"])) $advancedeadeststr = $ds["advance"];

    $ds = diffstr($td, $orderestimated);
    //var_dump($ds);
    if (isset($ds["lag"])) $lagestimated = $ds["lag"];
    if (isset($ds["advance"])) $advanceestimated = $ds["advance"];
    
    $ret = "<order>";
    $ret .= "<number>" . $_order_data["number"] . "</number>"; 
    $ret .= !is_null($_order_data["deadline"])? "<deadline>" . $_order_data["deadline"] . "</deadline>" : ""; 
    $ret .= !is_null($_order_data["baseline"])? "<baseline>" . $_order_data["baseline"] . "</baseline>" : "";
    $ret .= !is_null($_order_data["estimated"])? "<estimated>" . $_order_data["estimated"] . "</estimated> " : "";
    $ret .= isset($lagdeadbasestr)?"<lagdeadbase> " . $lagdeadbasestr . "</lagdeadbase>" : "";
    $ret .= isset($advancedeadbasestr)?"<advancedeadbase> " . $advancedeadbasestr . "</advancedeadbase>" : "";
    $ret .= isset($lagbaseeststr)?"<lagbaseest> " . $lagbaseeststr . "</lagbaseest>" : "";
    $ret .= isset($advancebaseeststr)?"<advancebaseest> " . $advancebaseeststr . "</advancebaseest>" : "";
    $ret .= isset($lagdeadeststr)?"<lagdeadest> " . $lagdeadeststr . "</lagdeadest>" : "";
    $ret .= isset($advancedeadeststr)?"<advancedeadest> " . $advancedeadeststr . "</advancedeadest>" : "";
    $ret .= isset($lagestimated)?"<lagestimated> " . $lagestimated . "</lagestimated>" : "";
    $ret .= isset($advanceestimated)?"<advanceestimated> " . $advanceestimated . "</advanceestimated>" : "";
    $ret .= "</order>";
    return $ret;
}
class naviProduct {
    
}

class naviOrder {
    private $structure;
    private $currentRoute;
    //private $
    function __construct() {
        
    }
    function __destruct() {
        
    }
    function __get($prop) {
		switch ($prop) {
			case "customer":
				return ;
			case "deadline":
				return ;
			case "baseline":
				return ;
			case "structure":
			    return ;
		}
    }
}
?>