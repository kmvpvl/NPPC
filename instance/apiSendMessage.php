<?php
include "checkUser.php";
try{
    $username = $_POST["message_to"];
    $user_id = $navi->getUserIDByName($username);
    var_dump($user_id);
    $order = $_POST["message_order"];
    $r = $navi->createMessage($_POST["message_text"], 
        $_POST["message_order"], 
        $user_id, 
        $_POST["message_type"], 
        (isset($_POST["message_reply"])?$_POST["message_reply"] : 0));
} catch (Exception $e) {
	http_response_code(400);
    echo 'Caught exception: ',  $e->getMessage(), "\n";
}
?>
