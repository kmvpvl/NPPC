<?php
include "checkORMNavi.php";
printNaviData(function($factory){
	$r = $factory->getWorkcenterOrders($_POST["data"]["workcenter"]);
    return $r;
});
?>