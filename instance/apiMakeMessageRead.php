<?php
include "checkUser.php";
try{
    $navi->makeMessageRead($_POST["message_id"]);
} catch (Exception $e) {
	http_response_code(400);
    echo 'Caught exception: ',  $e->getMessage(), "\n";
}
?>
