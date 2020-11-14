<?php
include "checkUser.php";
try{
    $r = $navi->calcOrderEstimatedTime($_POST["order_number"]);
    //var_dump($r);
} catch (Exception $e) {
	http_response_code(400);
    echo 'Caught exception: ',  $e->getMessage(), "\n";
}
?>
