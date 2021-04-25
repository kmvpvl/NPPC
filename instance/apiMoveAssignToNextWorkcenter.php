<?php
include "checkORMNavi.php";
printNaviData(function($factory){
    $factory->moveAssignToNextWorkcenter($_POST["data"]["assign"]);
    return null;
});
?>
