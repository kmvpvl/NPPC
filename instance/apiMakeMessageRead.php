<?php
include "checkUser.php";
try{
    $navi->makeMessageRead($_POST["message_id"]);
} catch (Exception $e) {
    echo 'Caught exception: ',  $e->getMessage(), "\n";
}
?>
