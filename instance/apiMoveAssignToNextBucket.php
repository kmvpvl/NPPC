<?php
include "checkORMNavi.php";
printNaviData(function($factory){
    $factory->moveAssignToNextBucket($_POST["data"]["assign"]);
    return null;
});
?>
