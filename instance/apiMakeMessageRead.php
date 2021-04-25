<?php
include "checkORMNavi.php";
printNaviData(function($factory){
    $factory->dismissMessage($_POST["data"]["message_id"]);
    return null;
});
?>
