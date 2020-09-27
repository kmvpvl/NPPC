<?php
include "classNavi.php";
echo '{"result":';
$res = '"OK"';
try {
	$navi = new naviClient($_POST['client'], $_POST['safetykey']);
	$x = $navi->getRoute($_POST['order'], $_POST['route']);
	$res .= ', "data" : ';
	$res .= json_encode($x);
} catch (Exception $e) {
    $res = '"FAIL", "description" : "' . $e->getMessage() . '"';  
}
echo $res . '}';
$shome = null;
?>
