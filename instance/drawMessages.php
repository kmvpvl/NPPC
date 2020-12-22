<?php
include "checkUser.php";
//var_dump($_POST);
try {
	$r = $navi->getMessages();
} catch (Exception $e) {
	http_response_code(400);
	die ($e->getMessage());
}
?>
<script>


</script>
<?php
foreach ($r as $msg) {
?>
<message message_id="<?= $msg["id"] ?>" class="<?= $msg["message_type"] ?>">
    <user><?= $msg["user_name"] ?></user>
    <message_time><?= $msg["message_time"] ?></message_time>
    <message_body><?= $msg["body"] ?></message_body>
</message>
<?php
}
?>
</div>
