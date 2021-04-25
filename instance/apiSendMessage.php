<?php
include "checkORMNavi.php";
printNaviData(function($factory){
    $message = new ORMNaviMessage($factory, $_POST["data"]["body"], $_POST["data"]["type"]);
    $message->send();
    return null;
});
?>
