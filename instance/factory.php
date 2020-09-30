<?php
include "checkUser.php";

?>
<script>
$(".navitem, .active").removeClass("active");
$("#menuFactory").addClass("active");
$(".navbar-brand").text("<?= $navi->factoryName ?>");
drawFactoryMap();

function factoryResize() {
	$("#factoryMap").outerHeight($("#instance-div").outerHeight() * 0.5);
	$("#content-div").css('height', $(window).height() - $("#content-div").offset().top + "px");
}

$(window).on ('resize', factoryResize);
factoryResize();

function drawFactoryMap() {
    $("#factoryMap").html = '';
	showLoading();
	var p = $.post("drawFactory.php",
	{
		username: $("#username").val(),
		password: $("#password").val(),
		factory:  $("#factory").val(),
		language: $("#language").val(),
		timezone: $("#timezone").val()
	},
	function(data, status){
		hideLoading();
		switch (status) {
			case "success":
				$("#factoryMap").html(data);
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
	<input type="text" class="form-control" placeholder="Search orders...">
	<div class="input-group-append">
  		<button class="btn btn-success" type="submit">Go</button> 
	</div>
</div>
<div id="factoryMap" class="ml-1 mr-1"></div>
<ul class="nav nav-tabs">
  <li class="nav-item">
    <a class="nav-link active primary" href="#">All</a>
  </li>
  <li class="nav-item">
    <a class="nav-link" href="#">Warnings</a>
  </li>
  <li class="nav-item">
    <a class="nav-link" href="#">Info</a>
  </li>
  <li class="nav-item">
    <a class="nav-link" href="#">Search</a>
  </li>
  <li class="nav-item">
    <a class="nav-link" href="#">New</a>
  </li>
</ul>
<div id="content-div" class="ml-1 mr-1">
	<div class="row mt-0">
		<div class="col-sm-6">
  <div class="toast fade show" data-autohide="false" id="toast1">
    <div class="toast-header">
      <strong class="mr-auto text-danger">Ready shafts warehouse</strong>
      <small class="text-muted">5 mins ago</small>
      <button type="button" class="ml-2 mb-1 close" data-dismiss="toast">&times;</button>
    </div>
    <div class="toast-body">
Stockman: Not enough places for ready shafts. Workshop will stop in 30 min
    </div>
  </div>
  <div class="toast fade show" data-autohide="false" id="toast3">
    <div class="toast-header">
      <strong class="mr-auto text-danger">Assembly workshop warehouse</strong>
      <small class="text-muted">just now</small>
      <button type="button" class="ml-2 mb-1 close" data-dismiss="toast">&times;</button>
    </div>
    <div class="toast-body">
Stockman: Supply of shats has stopped. Assembly wil stop in 2 hour
    </div>
  </div>
		</div>
		<div class="col-sm-6">
  <div class="toast fade show" data-autohide="false" id="toast2">
    <div class="toast-header">
      <strong class="mr-auto text-success">Ready whellpairs warehouse</strong>
      <small class="text-muted">1 mins ago</small>
      <button type="button" class="ml-2 mb-1 close" data-dismiss="toast">&times;</button>
    </div>
    <div class="toast-body">
Quality check: Order #2 ready to upload
    </div>
  </div>
		</div>
	</div>
</div>