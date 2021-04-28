<?php
include "checkORMNavi.php";
printNaviData(function($factory){
	$r = new ORMNaviOrder($factory, $_POST["data"]["order"]);
    $r->finish($_POST["data"]["conclusion"]);
    return $r;
});
?>