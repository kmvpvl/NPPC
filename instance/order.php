<?php
include "checkUser.php";
$brand = "Order #" . $_POST["order"];
$order_info = $navi->getOrderInfo($_POST["order"]);
//var_dump($order_info["assigns"]);
$navi->updateEstimatedTime($order_info);
?>
<script>
$(".nav-link.active").removeClass("active");
$("#menuWorkcenter").addClass("active");
$(".navbar-brand").text("<?= $brand ?>");
drawOrder();


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



</script>
<div class="row mt-0">
	<div class="col-sm-3 cell-header">Customer</div>
	<div class="col-sm-5 cell-header">Products&Count</div>
	<div class="col-sm-4 cell-header">Time</div>
</div>
<div class="row mt-0">
	<div class="col-sm-3 cell-data"><?=(string)$order_info["order"]->customer["ref"]?></div>
	<div class="col-sm-5 cell-data"><?=(string)$order_info["order"]->customer->product["ref"]?></div>
	<div class="col-sm-4 cell-data"><?="deadline: " .$order_info["db"]["deadline"] . "<br>" . "baseline: " .$order_info["db"]["baseline"] . "<br>" ."estimated: " .$order_info["db"]["estimated"] . "<br>" .order_db_string($order_info["db"])?></div>
</div>

<?php
//var_dump();
foreach ($order_info["assigns"] as $a) {
    echo ($a["event_time"] . " - <span wc='" . $a["workcenter_name"] . "'>" . $a["workcenter_name"] . "</span>: " . (($a["bucket"] == "") ? "finished" : $a["operation"] . " " . $a["bucket"]) . (($a["bucket"] == "OUTCOME") ? "<span road=" . $a["road_name"] . "> road </span>" : "" . " ") .  "<br>");
}
?>
<script>
$('span[wc]').on('click', function(event){
    workcenter(event.target.attributes.wc.value, '<?= $_POST["order"]?>');
    
});
$('span[road]').on('click', function(event){
    road(event.target.attributes.road.value, '<?= $_POST["order"]?>');
    
});
</script>

<div id="messageCenter" class="messageCenter">

</div>