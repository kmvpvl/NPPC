<?php
include "checkORMNavi.php";
try {
	$r = $factory->getIncomingMessages();
    $ls = addslashes(json_encode($r, JSON_HEX_APOS | JSON_HEX_QUOT));
} catch (Exception $e) {
	http_response_code(400);
	die ($e->getMessage());
}
?>
<script>
ls = JSON.parse('<?=$ls?>');
for (ind in ls) {
    m = new ORMNaviMessage(ls[ind]);
}
</script>
<?php
foreach ($r as $msg) {
?>
<message message_id="<?= $msg->id ?>"></message>
<?php
}
?>
</div>
