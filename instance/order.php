<?php
include "checkUser.php";
$brand = "Order #" . $_POST["order"];
$order_info = $navi->getOrderInfo($_POST["order"]);
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
<div class="row mt-0">
	<div class="col-sm-3 cell-header">Customer</div>
	<div class="col-sm-5 cell-header">Products&Countt</div>
	<div class="col-sm-2 cell-header">Deadline</div>
	<div class="col-sm-2 cell-header">Estimated</div>
</div>
<div class="row mt-0">
	<div class="col-sm-3 cell-data"><?=(string)$order_info["order"]->customer["ref"]?></div>
	<div class="col-sm-5 cell-data"><?=(string)$order_info["order"]->customer->product["ref"]?></div>
	<div class="col-sm-2 cell-data"><?=(string)$order_info["order"]->customer->product["overall_duration"]?></div>
	<div class="col-sm-2 cell-data"><?=(string)$order_info["order"]->customer->product["overall_duration"]?></div>
</div>
<?php
foreach ($order_info["assigns"] as $a) {
    echo ($a["event_time"] . " - <span wc='" . $a["workcenter_name"] . "'>" . $a["workcenter_name"] . "</span>: " . (($a["operation"] == "") ? "finished" : $a["operation"] . " " . $a["bucket"]) . "<br>");
}
?>
<script>
$('span[wc]').on('click', function(event){
    workcenter(event.target.attributes.wc.value);
    
});
</script>

<div id="messageCenter" class="messageCenter">

</div>