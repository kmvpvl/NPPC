<?php
include "checkORMNavi.php";
try {
    $factory->moveAssignToNextWorkcenter($_POST["data"]["assign"]);
} catch (ORMNaviException | Exception $e) {
	http_response_code(400);
	die ($e->getMessage());
}
?>
