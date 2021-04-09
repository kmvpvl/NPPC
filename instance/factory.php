<?php
include "checkUser.php";

?>
<script>
//debugger;
$(".nav-link.active").removeClass("active");
$(".nav-item.active").removeClass("active");
$("#menuFactory").addClass("active");
$(".navbar-brand").text("<?= $navi->factoryName ?>: Overview");
drawFactoryMap();

function drawFactoryMap() {
    $("#factoryMap").html('');
	sendDataToNavi("drawFactory", undefined,
		function(data, status) {
			hideLoading();
			switch (status) {
				case "success":
					$("#factoryMap").html(data);
					resizeFactoryMap();
					break;
				default:
					;
			}
		});
}
$(window).resize(function(){
	resizeFactoryMap();
});
</script>
<factory>
<input type="text" class="form-control" placeholder="Search orders or anything..."></input>
<div id="factoryMap"></div>
</factory>