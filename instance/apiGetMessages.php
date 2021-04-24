<?php
include "checkORMNavi.php";
printNaviData(function($factory){
	$r = $factory->getMessages();
    return $r;
});
?>