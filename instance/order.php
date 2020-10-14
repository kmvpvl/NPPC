<?php
include "checkUser.php";
$brand = "Order #" . $_POST["order"];
$order_info = $navi->getOrderInfo($_POST["order"]);
var_dump($order_info);
?>
<script>
$(".nav-link.active").removeClass("active");
$("#menuWorkcenter").addClass("active");
$(".navbar-brand").text("<?= $brand ?>");
drawOrder();
drawMessages();


function messageCenterResize() {
    //debugger;
	//$("#factoryMap").outerHeight($("#instance-div").outerHeight());
	if (typeof(resizeMessageCenter) == "function") resizeMessageCenter();	
}

function resizeOrderContentAll() {
    messageCenterResize();
}

$(window).on ('resize', resizeOrderContentAll);

//resizeWorkcenterContentAll();

function drawOrder() {
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
<div class="input-group mb-3">
	<input type="text" class="form-control" placeholder="Search orders...">
	<div class="input-group-append">
  		<button class="btn btn-success" type="submit">Go</button> 
	</div>
</div>
<?php
?>
<div class="row mt-0">
	<div class="col-sm-2 cell-header">#</div>
	<div class="col-sm-2 cell-header">Customer</div>
	<div class="col-sm-4 cell-header">Products&Countt</div>
	<div class="col-sm-2 cell-header">Deadline</div>
	<div class="col-sm-2 cell-header">Estimated</div>
</div>
<div class="row mt-0">
	<div class="col-sm-2 cell-data"></div>
	<div class="col-sm-2 cell-data"></div>
	<div class="col-sm-4 cell-data"></div>
	<div class="col-sm-2 cell-data"></div>
	<div class="col-sm-2 cell-data"></div>
</div>
<div id="messageCenter" class="messageCenter">

</div>