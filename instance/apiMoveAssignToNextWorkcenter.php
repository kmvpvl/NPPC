<?php
include "checkUser.php";
try {
    $navi->moveAssignToNextWorkcenter($_POST["assign_id"]);
} catch (Exception $e) {
	http_response_code(400);
	die ($e->getMessage());
}
?>
