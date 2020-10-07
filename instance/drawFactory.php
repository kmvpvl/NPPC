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
	function resizeFactoryMap() {
		map = new nppcMap("<?=$navi->factoryMap?>", $("#factoryMap").innerWidth(), $("#factoryMap").innerHeight());
		<?= $r->script ?>
	}
	$('rect.workcenter').on('click', function(event) {
    	$('[data-toggle="tooltip"]').hide();   
        workcenter(event.target.id); 
	});
</script>
