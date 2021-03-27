<?php
include "checkORMNavi.php";
echo '{"result":';
$res = '"OK"';
try {
	$r = new ORMNaviOrder($factory, $_POST["data"]["order_number"]);
    $ls = json_encode($r, JSON_HEX_APOS | JSON_HEX_QUOT);
    $res .= ', "data" : ';
    $res .= $ls;
} catch (ORMNaviException | Exception $e) {
    $res = '"FAIL", "description" : "' . $e->getMessage() . '"';  
}
echo $res . '}';
?>