<?php
include "checkUser.php";
try {
    $navi->moveAssignToNextBucket($_POST["assign_id"]);
} catch (Exception $e) {
	http_response_code(400);
	die ($e->getMessage());
}
?>
