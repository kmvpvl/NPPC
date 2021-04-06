<?php
include "checkORMNavi.php";
echo '{"result":';
$res = '"OK"';
try {
	$w = $factory->getWorkcentersWorkload();
    $r = $factory->getRoadsWorkload();
    $uu = $factory->getUsersList();
    $ls = json_encode([
        'user'=>$factory->user,
        'workloads'=>['workcenters'=>$w, 'roads'=>$r],
        'users'=> $uu
    ], JSON_HEX_APOS | JSON_HEX_QUOT);
    $res .= ', "data" : ';
    $res .= $ls;
} catch (ORMNaviException | Exception $e) {
    $res = '"FAIL", "description" : "' . $e->getMessage() . '"';  
}
echo $res . '}';
?>