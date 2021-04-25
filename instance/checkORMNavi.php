<?php
require_once "classORMNavi.php";

function printNaviData($callback){
	global $factory;
    $ret = [];
    try {
        $ret["data"] = $callback($factory);
        $ret["result"] = "OK";
    } catch (ORMNaviException | Exception $e) {
        $ret["result"] = "FAIL";
        $ret["description"] = $e->getMessage();
    }
    echo json_encode($ret, JSON_HEX_APOS | JSON_HEX_QUOT);
}

try {
	$factory = new ORMNaviFactory($_POST['username'], $_POST['password'], $_POST['factory'], new DateTimeZone($_POST['timezone']));
} catch (Exception | ORMNAviException $e) {
	http_response_code(401);
	die ($e->getMessage());
}
?>