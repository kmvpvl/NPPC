<?php
include "checkUser.php";
try{
    //var_dump($_POST);
	$found = $navi->getUserByLetters($_POST['letters']);
	echo json_encode($found);
} catch (Exception $e) {
	http_response_code(400);
    echo 'Caught exception: ',  $e->getMessage(), "\n";
}
?>

