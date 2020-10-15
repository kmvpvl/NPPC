<?php
include "checkUser.php";

?>
<script>
$(".nav-item.active").removeClass("active");
$("#menuFactory").addClass("active");
$(".navbar-brand").text("<?= $navi->factoryName ?>");
drawFactoryMap();
drawMessages();

function factoryResize() {
	//$("#factoryMap").outerHeight($("#instance-div").outerHeight());
	if (typeof(resizeFactoryMap) == "function") resizeFactoryMap();	
}

function messageCenterResize() {
	//$("#factoryMap").outerHeight($("#instance-div").outerHeight());
	if (typeof(resizeMessageCenter) == "function") resizeMessageCenter();	
}

function resizeFactoryContentAll() {
    factoryResize();
    messageCenterResize();
}

$(window).on ('resize', resizeFactoryContentAll);

resizeFactoryContentAll();

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

function drawMessages() {
    $("#messageCenter").html = '';
	showLoading();
	var p = $.post("drawMessages.php",
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
				$("#messageCenter").html(data);
				resizeMessageCenter();	
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
<div id="factoryMap" class="ml-1 mr-1"></div>
<div class="input-group mb-3">
	<input type="text" class="form-control" placeholder="First letters of order's number...">
	<div class="input-group-append">
  		<button class="btn btn-success" type="submit">Search</button> 
	</div>
</div>

<div id="messageCenter" class="messageCenter popdown">

</div>