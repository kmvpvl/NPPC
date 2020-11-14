<?php
include "classNavi.php";

try {
	$navi = new naviClient($_POST['username'], $_POST['password'], $_POST['factory'], $_POST['timezone']);
} catch (Exception $e) {
	http_response_code(401);
	die ($e->getMessage());
}
?>