<?php
include "checkORMNavi.php";
try{
    $message = new ORMNaviMessage($factory, $_POST["data"]["body"], $_POST["data"]["type"]);
    $message->send();
} catch (Exception $e) {
	http_response_code(400);
    echo 'Caught exception: ',  $e->getMessage(), "\n";
}
?>
