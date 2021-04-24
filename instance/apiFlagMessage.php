<?php
include "checkORMNavi.php";
printNaviData(function($factory){
    $factory->flagMessage($_POST["data"]["message_id"], $_POST["data"]["flag"]);
    return null;
});
?>
