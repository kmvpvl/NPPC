<?php
include "checkORMNavi.php";
try{
    $factory->dismissMessage($_POST["data"]["message_id"]);
} catch (Exception $e) {
	http_response_code(400);
    echo 'Caught exception: ',  $e->getMessage(), "\n";
}
?>