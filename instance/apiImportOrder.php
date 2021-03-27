<?php
include "checkORMNavi.php";
try{
    $orders = $_POST["data"]["orders"];
    $routes = $_POST["data"]["routes"];
    foreach ($orders as $k=>$o) {
        $order = new ORMNaviOrder($factory, $o);
        $order->assignOrderRoute($routes[$k]);
    }
} catch (Exception $e) {
	http_response_code(400);
    echo 'Caught exception: ',  $e->getMessage(), "\n";
}
?>