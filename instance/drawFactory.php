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
	function resizeFactoryMap() {
		map = new nppcMap("<?=$navi->factoryMap?>", $("#factoryMap").innerWidth(), $("#factoryMap").innerHeight());
		<?= $r->script ?>
	}
	$('rect.workcenter').on('click', function(event) {
        workcenter(event.target.id); 
	});
	$('line.road').on('click', function(event) {
        road(event.target.id); 
	});
</script>
