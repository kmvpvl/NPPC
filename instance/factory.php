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

function factoryResize() {
    //debugger;
	$("#factoryMap").css('height', $("#factoryMap").parent().innerHeight()-$("#factoryMap").position().top);
	if (typeof(resizeFactoryMap) == "function") resizeFactoryMap();	
}


$(window).on ('resize', factoryResize);

factoryResize();

function drawFactoryMap() {
    $("#factoryMap").html = '';
	showLoading();
	var p = $.post("drawFactory.php",
	{
		username: $("#username").val(),
		factory:  $("#factory").val(),
		password: $("#password").val(),
		language: $("#language").val(),
		timezone: $("#timezone").val()
	},
	function(data, status){
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
	p.fail(function(data, status) {
		hideLoading();
		switch (data.status) {
			case 401:
				clearInstance();
				showLoginForm();
				showLoadingError(data.status + ": " + data.statusText + ". " + data.responseText);
				break;
			default:				
				showLoadingError(data.status + ": " + data.statusText + ". " + data.responseText);
		}
	})
}

</script>
<div class="input-group mb-3">
	<input type="text" class="form-control" placeholder="Search orders or anything...">
	<button>[Update baselines]</button>
	<button>[Update estimates]</button>
	<button>[Update info]</button>
</div>
<div id="factoryMap" class="ml-1 mr-1"></div>
