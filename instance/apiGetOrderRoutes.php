<?php
include "classNavi.php";
echo '{"result":';
$res = '"OK"';
try {
	$navi = new naviClient($_POST['client'], $_POST['safetykey']);
	$x = $navi->getRoutes($_POST['order']);
	$res .= ', "data" : ';
	$res .= json_encode($x);
} catch (Exception $e) {
    $res = '"FAIL", "description" : "' . $e->getMessage() . '"';  
}
echo $res . '}';
?>
