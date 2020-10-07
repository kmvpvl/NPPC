<?php
include "checkUser.php";
try{
    $navi->assignOrderRoute("1", 1);
} catch (Exception $e) {
    echo 'Caught exception: ',  $e->getMessage(), "\n";
}
?>

