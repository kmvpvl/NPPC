<?php
include "checkORMNavi.php";
printNaviData(function($factory){
    $orders = $_POST["data"]["orders"];
    foreach ($orders as $o) {
        $order = new ORMNaviOrder($factory, $o);
        $order->updateEstimatedTime($_POST["data"]["updatebaseline"]);
    }
    return null;
});
?>