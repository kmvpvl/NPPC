<?php
include "checkORMNavi.php";
printNaviData(function($factory){
	$r = new ORMNaviOrder($factory, $_POST["data"]["order_number"]);
    return $r;
});
?>