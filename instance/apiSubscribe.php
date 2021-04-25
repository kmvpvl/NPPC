<?php
include "checkORMNavi.php";
printNaviData(function($factory){
    $tag = $_POST["data"]["tag"];
	$r = $factory->user->subscribe($tag);
    return $r;
});
?>