<?php
include "checkORMNavi.php";
echo '{"result":';
$res = '"OK"';
$d = $_POST["data"];
try {
	$r = $factory->saveUser(isset($d["id"])?$d["id"]:null, $d["name"], null, $d["roles"], $d["subscriptions"]);
    $ls = json_encode($r, JSON_HEX_APOS | JSON_HEX_QUOT);
    $res .= ', "data" : ';
    $res .= $ls;
} catch (ORMNaviException | Exception $e) {
    $res = '"FAIL", "description" : "' . $e->getMessage() . '"';  
}
echo $res . '}';
?>