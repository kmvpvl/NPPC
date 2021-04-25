<?php
include "checkORMNavi.php";
printNaviData(function($factory){
    $d = $_POST["data"];
    $r = $factory->saveUser(isset($d["id"])?$d["id"]:null, $d["name"], null, $d["roles"], $d["subscriptions"]);
    return $r;
});
?>