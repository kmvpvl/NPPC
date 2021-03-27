<?php
include "checkORMNavi.php";
echo '{"result":';
$res = '"OK"';
try {
	$r = $factory->getRoadOrders($_POST["data"]["road"]);
    $ls = json_encode($r, JSON_HEX_APOS | JSON_HEX_QUOT);
    $res .= ', "data" : ';
    $res .= $ls;
} catch (Exception $e) {
    $res = '"FAIL", "description" : "' . $e->getMessage() . '"';  
}
echo $res . '}';
?>