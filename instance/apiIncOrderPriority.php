<?php
include "checkORMNavi.php";
printNaviData(function($factory){
    $o = new ORMNaviOrder($factory, $_POST["data"]["order"]);
    $o->incPriority($_POST["data"]["delta"]);
    return $o;
});
?>