<?php
include "checkORMNavi.php";
printNaviData(function($factory){
    $orders = $_POST["data"]["orders"];
    $routes = $_POST["data"]["routes"];
    foreach ($orders as $k=>$o) {
        $order = new ORMNaviOrder($factory, $o);
        $order->assignOrderRoute($routes[$k]);
        if ($_POST["data"]["subscribe_me"]) $factory->user->subscribe("#".$o);
        if (isset($_POST["data"]["subscribe_user"])) {
            $tmp = "The order #".$o." started. The owner of order is @".(strpos($_POST["data"]["subscribe_user"], " ")?('"'.$_POST["data"]["subscribe_user"].'"'):$_POST["data"]["subscribe_user"])." - ". $_POST["data"]["message_text"];
            $msg = new ORMNaviMessage($factory, $tmp, ORMNaviMessageType::WARNING);
			$msg->send();        
            $factory->subscribeUser($_POST["data"]["subscribe_user"], "#".$o);
        }
    }
    return null;
});
?>