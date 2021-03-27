<?php
include "checkORMNavi.php";
try{
    $orders = $_POST["data"]["orders"];
    foreach ($orders as $o) {
        $order = new ORMNaviOrder($factory, $o);
        $order->updateEstimatedTime($_POST["data"]["updatebaseline"]);
    }
} catch (Exception $e) {
	http_response_code(400);
    echo 'Caught exception: ',  $e->getMessage(), "\n";
}
?>