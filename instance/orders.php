<?php
include "checkUser.php";
?>
<script>
$(".nav-link.active").removeClass("active");
$(".nav-item.active").removeClass("active");
$("#menuOrders").addClass("active");
$(".navbar-brand").text("<?= $navi->factoryName ?>: Orders");
drawOrders();

function ordersResize() {
    //debugger;
    $(".content-div").outerHeight($("#instance-div").outerHeight() - $(".content-div").position().top);
}


function resizeOrdersContentAll() {
    ordersResize();
}

$(window).on ('resize', resizeOrdersContentAll);

resizeOrdersContentAll();

function drawOrders() {
}


$("#btn-move-assign").on("click", function(){
	showLoading();
	var p = $.post("apiMoveAssignToNextBucket.php",
	{
		username: $("#username").val(),
		password: $("#password").val(),
		factory:  $("#factory").val(),
		language: $("#language").val(),
		timezone: $("#timezone").val(),
		assign_id: $(".active[assign]").attr("assign")
	},
	function(data, status){
		hideLoading();
		switch (status) {
			case "success":
			    //debugger;
			    workcenter("");
				break;
			default:
				clearInstance();
				showLoginForm();
		}
	});
	p.fail(function(data, status) {
		hideLoading();
		switch (data.status) {
			case 400:
				clearInstance();
				showLoginForm();
				showLoadingError(data.status + ": " + data.statusText + ". " + data.responseText);
				break;
			default:				
				showLoadingError(data.status + ": " + data.statusText + ". " + data.responseText);
		}
	})
})
$("[order][type='INCOME']").on ('click', function (event) {
    var c = event.target;
    if (c.classList.contains("active")) {
        c.classList.remove("active");
        $("#income-selected-count").text(Number($("#income-selected-count").text()) - 1);
    } else {
        c.classList.add("active");
        $("#income-selected-count").text(Number($("#income-selected-count").text()) + 1);
    }
})
</script>
<?php
$fs = $navi->getOrdersForImport();
//var_dump($fs);
?>
<div class="row ml-0 mr-0">
	<div class="col-sm-6 cell-header"><span>+</span><input type="text" placeholder="Search..."><span>-</span></div>
	<div class="col-sm-6 cell-header"><span>+</span><input type="text" placeholder="Search..."><span>-</span></div>
</div>
<div class="row ml-0 mr-0">
	<div class="col-sm-6 cell-header">INCOME <span id="income-selected-count">0</span> of <?=count($fs)?></div>
	<div class="col-sm-6 cell-header">PROCESSING<span></span></div>
</div>
<div class="content-div">
<?php
foreach ($fs as $fn) {
?>
<div class="row ml-0 mr-0">
	<div class="col-sm-6 cell-data" type="INCOME" order="<?= $fn?>"><?= $fn?></div>
	<div class="col-sm-6 cell-data">&nbsp;</div>
</div>
<?php
};
?>
</div>
