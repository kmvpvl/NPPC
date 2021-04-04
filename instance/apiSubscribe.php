<?php
include "checkORMNavi.php";
$tag = $_POST["data"]["tag"];
echo '{"result":';
$res = '"OK"';
try {
	$r = $factory->user->subscribe($tag);
    $ls = json_encode($r, JSON_HEX_APOS | JSON_HEX_QUOT);
    $res .= ', "data" : ';
    $res .= $ls;
} catch (ORMNaviException | Exception $e) {
    $res = '"FAIL", "description" : "' . $e->getMessage() . '"';  
}
echo $res . '}';
?>