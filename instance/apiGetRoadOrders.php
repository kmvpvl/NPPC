<?php
include "checkORMNavi.php";
printNaviData(function($factory){
	$r = $factory->getRoadOrders($_POST["data"]["road"]);
    return $r;
});
?>