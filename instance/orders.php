<?php
include "checkORMNavi.php";
?>
<script>
$(".nav-link.active").removeClass("active");
$(".nav-item.active").removeClass("active");
$("#menuOrders").addClass("active");
$(".navbar-brand").text("<?= $factory->description ?>: Orders");
function ordersUpdated(data, status) {
	hideLoading();
	$("orders_to_import").html("");
	$("orders_inprocess").html("");
	switch (status) {
		case "success":
			ls = JSON.parse(data);
			for (ind in ls.data) {
				o = ls.data[ind];
				if (o.id) {
					$("orders_inprocess").append('<order class="brief" number="'+o.number+'"/>');
				} else {
					$("orders_to_import").append('<order class="brief" number="'+o.number+'"/>');
				}
				ot = new ORMNaviOrder(o);
			}
			$("order[number]").on('click', function() {
				//debugger;
				var n = $(this).attr("number");
				if ($('order[number="'+n+'"]').hasClass("selected")) $('order[number="'+n+'"]').removeClass("selected");
				else $('order[number="'+n+'"]').addClass("selected");
				if ($("order[number].selected").length == 1) {
					//debugger;
					$("#btnOrderInfo").show();
					$("#btnOrderInfo").css({
						left: $("order[number].selected").position().left/*+$("order[number].selected").outerWidth()*/+'px',
						top: $("order[number].selected").position().top+$("order[number].selected").outerHeight()+'px'
					});
				} else {
					$("#btnOrderInfo").hide();
				}
			})
			break;
		default:
			;
	}
}
function updateAllOrders() {
	sendDataToNavi("apiGetAllOrders", undefined, ordersUpdated);
}
$("#btnUpdateEstimated").on('click', function() {
	var a = $("orders_inprocess > order.selected");
	var data = [];
	a.each(function(ind, value){
		data.push($(value).attr("number"));
	});
	sendDataToNavi("apiUpdateEstimated", {updatebaseline: 0, orders: data}, estimatedUpdated);
})
$("#btnUpdateBaseline").on('click', function() {
	var a = $("orders_inprocess > order.selected");
	var data = [];
	a.each(function(ind, value){
		data.push($(value).attr("number"));
	});
	sendDataToNavi("apiUpdateEstimated", {updatebaseline: 1, orders: data}, estimatedUpdated);
})
$("#btnImportOrders").on('click', function() {
	var a = $("orders_to_import > order.selected");
	var o = [];
	var r = [];
	a.each(function(ind, value){
		o.push($(value).attr("number"));
		r.push(1);
	});
	sendDataToNavi("apiImportOrder", {orders: o, routes: r}, function (data, status) {
		hideLoading();
		switch (status) {
			case "success":
				updateAllOrders();
				showInformation("Orders were imported");
				break;
			default:
				;
		}
	});
})
function estimatedUpdated(data, status) {
	hideLoading();
	switch (status) {
		case "success":
			updateAllOrders();
			showInformation("Estimated dates were updated!");
			break;
		default:
			;
	}
}
$("#btnInprocessSelectAll").on('click', function(){
	$("orders_inprocess > order").addClass("selected");
})
updateAllOrders();
$("#btnOrderInfo").on('click', function(){
    if ($("order[number].selected").length == 1) {
        var order = $("order[number].selected").attr("number");
        modalOrderInfo(order);
    }
});
</script>
<?php
?>
<orders>
	<input type="text" placeholder="Ready to import Search..."></input>
	<input type="text" placeholder="In process Search..."></input>
	<div>
		<span class="th-5">Order</span>
		<span class="th-5">Deadline</span>
	</div>
	<div>
		<span class="th-5">Order</span>
		<span class="th-5">Deadline</span>
		<span class="th-4">Est</span>
		<span class="th-4">Plan</span>
	</div>
	<orders_to_import>
	</orders_to_import>
	<orders_inprocess>
	</orders_inprocess>
	<div>
		<button>Select All</button>
		<button id="btnImportOrders">Import</button>
	</div>
	<div>
		<button id="btnInprocessSelectAll">Select All</button>
		<button id="btnUpdateEstimated">Update est.</button>
		<button id="btnUpdateBaseline">Update plan</button>
	</div>
</orders>
<div id="dlg-orderImport" style="display:none;">
	<label for="recipient-name" class="col-form-label">Recipient:</label>
	<input type="text" class="form-control" id="recipient-name"></input>
	<label for="message-text" class="col-form-label">Message:</label>
	<textarea class="form-control" id="message-text"></textarea>
</div>
<span id="btnOrderInfo">info</span>
