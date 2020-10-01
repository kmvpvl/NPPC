<?php
include "checkUser.php";
try {
	$r = $navi->drawFactory();
} catch (Exception $e) {
	http_response_code(400);
	die ($e->getMessage());
}
echo $r->html;
?>
<script>
	$('[data-toggle="tooltip"]').tooltip();   
	map = new nppcMap("<?=$navi->factoryMap?>", $("#factoryMap").innerWidth(), $("#factoryMap").innerHeight());
	function resizefactoryMap() {
		<?= $r->script ?>
	}
</script>
