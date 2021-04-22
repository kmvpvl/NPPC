<?php
include "checkORMNavi.php";
echo '{"result":';
$res = '"OK"';
try {
    $o = new ORMNaviOrder($factory, $_POST["data"]["order"]);
    $o->incPriority($_POST["data"]["delta"]);
    $ls = json_encode($o, JSON_HEX_APOS | JSON_HEX_QUOT);
    $res .= ', "data" : ';
    $res .= $ls;
} catch (ORMNaviException | Exception $e) {
    $res = '"FAIL", "description" : "' . $e->getMessage() . '"';  
}
echo $res . '}';
?>