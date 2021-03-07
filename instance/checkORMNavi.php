<?php
require_once "classORMNavi.php";

try {
	$factory = new ORMNaviFactory($_POST['username'], $_POST['password'], $_POST['factory'], new DateTimeZone($_POST['timezone']));
} catch (Exception | ORMNAviException $e) {
	http_response_code(401);
	die ($e->getMessage());
}
?>