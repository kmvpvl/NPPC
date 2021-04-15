<?php
require_once("classORMNavi.php");
$tz = new DateTimeZone("+0300");
$factory = new ORMNaviFactory("David Rhuxel", "1", "example2", $tz);
//$message = new ORMNaviMessage($factory, 'Заказ #o-23223/222-1 успешно. @Иванов завершай,  asap');
//$message->send();
//echo json_encode($message);
//$a = $factory->getIncomingMessages(1);
//foreach ($a as $key => $value) {
//    $value->dismiss();
//}
//echo json_encode($a);
//$o = new ORMNaviOrder($factory, "o-259"/*, new DateTime(), "c2", "1"*/);
//$o->route();
//$oo = $factory->getAllOrders();
echo json_encode($factory);
?>