<?php
include "checkORMNavi.php";
echo '{"result":';
$res = '"OK"';
try {
	$w = $factory->getWorkcentersWorkload();
    $r = $factory->getRoadsWorkload();
    $ls = json_encode(['workcenters'=>$w, 'roads'=>$r], JSON_HEX_APOS | JSON_HEX_QUOT);
    $res .= ', "data" : ';
    $res .= $ls;
} catch (ORMNaviException | Exception $e) {
    $res = '"FAIL", "description" : "' . $e->getMessage() . '"';  
}
echo $res . '}';
?>