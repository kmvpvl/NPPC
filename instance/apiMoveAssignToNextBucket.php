<?php
include "checkORMNavi.php";
try {
    $factory->moveAssignToNextBucket($_POST["data"]["assign"]);
} catch (ORMNaviException | Exception $e) {
	http_response_code(400);
	die ($e->getMessage());
}
?>
