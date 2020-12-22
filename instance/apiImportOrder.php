<?php
include "checkUser.php";
try{
    //var_dump($_POST);
    foreach ($_POST["order_number"] as $order_number) {
        $oid = $navi->assignOrderRoute($order_number, $_POST["route"]);
        if (isset($_POST["message"])) {
            $navi->createMessage($_POST["message"], $oid);
        }
    }
} catch (Exception $e) {
	http_response_code(400);
    echo 'Caught exception: ',  $e->getMessage(), "\n";
}
?>

