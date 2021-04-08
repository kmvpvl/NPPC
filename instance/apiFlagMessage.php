<?php
include "checkORMNavi.php";
try{
    $factory->flagMessage($_POST["data"]["message_id"], $_POST["data"]["flag"]);
} catch (ORMNaviException | Exception $e) {
	http_response_code(400);
    echo 'Caught exception: ',  $e->getMessage(), "\n";
}
?>
