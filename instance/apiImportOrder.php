<?php
include "checkUser.php";
try{
    $navi->assignOrderRoute("1", 1);
    $navi->assignOrderRoute("ord12", 1);
    $navi->assignOrderRoute("ord13", 1);
    $navi->assignOrderRoute("ord14", 1);
    $navi->assignOrderRoute("ord15", 1);
    $navi->assignOrderRoute("2386", 1);
} catch (Exception $e) {
    echo 'Caught exception: ',  $e->getMessage(), "\n";
}
?>

