<?php
include "checkORMNavi.php";
printNaviData(function($factory){
	$r = $factory->getAllOrders();
    return $r;
});
?>