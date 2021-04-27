<?php
include "checkORMNavi.php";
$factory->hasRoleOrDie(["IMPORT_ORDER"]);
?>
<script>
$(".nav-link.active").removeClass("active");
$(".nav-item.active").removeClass("active");
$("#menuOrders").addClass("active");
$(".navbar-brand").text(NaviFactory.name + ": Orders");

function updateAllOrders() {
	sendDataToNavi("apiGetAllOrders", undefined, function(data, status) {
		$("orders-to-import").html("");
		$("orders-inprocess").html("");
		var ls = recieveDataFromNavi(data, status);
		if (ls && ls.result=='OK') {
			for (let [i, o] of Object.entries(ls.data)) {
                var $o = $('<order class="brief"/>');
                var ot = new ORMNaviOrder(o, $o);
				ot.showOperation(null, false);
				if (o.id) {
					$("orders-inprocess").append($o);
					ot.showOperation(['info','priority-up', 'priority-down'], true);
				} else {
					$("orders-to-import").append($o);
					ot.showOperation(['info'], true);
				}
				ot.on('operation', function(order, cntxt){
					switch (cntxt.operation){
						case 'info':
							modalOrderInfo(order.number);
							break;
						case 'priority-up':
							sendDataToNavi('apiIncOrderPriority', {order: order.number, delta: 1}, function(data, status){
								var ls = recieveDataFromNavi(data, status);
								if (ls && ls.result=='OK') {
									updateAllOrders();
									showInformation("Priority was changed!");
								}
							});
							break;
						case 'priority-down':
							sendDataToNavi('apiIncOrderPriority', {order: order.number, delta: -1}, function(data, status){
								var ls = recieveDataFromNavi(data, status);
								if (ls && ls.result=='OK') {
									updateAllOrders();
									showInformation("Priority was changed!");
								}
							});
						break;
						default:
					}
				});
			}
			$("order[number]").on('click', function() {
				var n = $(this).attr("number");
				if ($('order[number="'+n+'"]').hasClass("selected")) $('order[number="'+n+'"]').removeClass("selected");
				else $('order[number="'+n+'"]').addClass("selected");
				if ($("order[number].selected").length == 1) {
				}
			});
		}
	});
}
$("#btnUpdateEstimated").on('click', function() {
	var a = $("orders-inprocess > order.selected");
	var data = [];
	a.each(function(ind, value){
		data.push($(value).attr("number"));
	});
	sendDataToNavi("apiUpdateEstimated", {updatebaseline: 0, orders: data}, estimatedUpdated);
})
$("#btnUpdateBaseline").on('click', function() {
	var a = $("orders-inprocess > order.selected");
	var data = [];
	a.each(function(ind, value){
		data.push($(value).attr("number"));
	});
	sendDataToNavi("apiUpdateEstimated", {updatebaseline: 1, orders: data}, estimatedUpdated);
})
$("#btnImportOrders").on('click', function() {
	var a = $("orders-to-import > order.selected");
	$("orders-to-import-list").text("");
	a.each(function(ind, value){
		$("orders-to-import-list").append($(value).attr("number") + " ");
	});
	$("#dlgImportOrderModal").modal('show');
})
function estimatedUpdated(data, status) {
	var ls = recieveDataFromNavi(data, status);
	if (ls && ls.result=='OK') {
		updateAllOrders();
		showInformation("Estimated dates were updated!");
	}
}
$("#btnInprocessSelectAll").on('click', function(){
	$("orders-inprocess > order").addClass("selected");
})
updateAllOrders();
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
	<orders-to-import>
	</orders-to-import>
	<orders-inprocess>
	</orders-inprocess>
	<div>
		<button>Select All</button>
		<button id="btnImportOrders">Import</button>
	</div>
	<div>
		<button id="btnInprocessSelectAll">Select All</button>
<?php
if ($factory->user->hasRole("UPDATE_ESTIMATED")) {
?>
		<button id="btnUpdateEstimated">Update est.</button>
<?php
}
if ($factory->user->hasRole("UPDATE_BASELINE")) {
?>
		<button id="btnUpdateBaseline">Update plan</button>
<?php
}
?>
	</div>
</orders>
<div class="modal fade" id="dlgImportOrderModal" tabindex="-1" role="dialog" aria-labelledby="dlgOrderImportModalLongTitle" aria-hidden="true">
  <div class="modal-dialog" role="document">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="dlgOrderImportModalLongTitle">Import orders</h5>
        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
          <span aria-hidden="true">&times;</span>
        </button>
      </div>
      <div class="modal-body">
		<orders-to-import-list></orders-to-import-list>
		<div>
        <input id="chk-subscribe-user" type="checkbox" checked>Subscribe user</input>
		<select id="slct-import-order-owner"></select>
		</div>
        <input id="chk-subscribe-me" type="checkbox" checked>Subscribe me</input>
		<div class="input-group">
		<div class="input-group-prepend">
		<span class="input-group-text">Text</span>
		<!--select class="custom-select" id="slct-import-order-type">
				<option value="INFO">info</option>
				<option value="WARNING">warning</option>
				<option value="CRITICAL">critical</option>
			</select-->
		</div>
		<textarea id="text-import-order-text" class="form-control" aria-label="With textarea" rows="1"></textarea>
		<div class="input-group-append">
			<!--button id="btn-send-message" class="btn btn-outline-secondary" type="button">Send</button-->
		</div>
		</div>
      </div>
      <div class="modal-footer">
    	<button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
    	<button id="btn-import-order" type="button" class="btn btn-success" data-dismiss="modal">Import</button>
      </div>
    </div>
  </div>
</div>
<script>
$("#chk-subscribe-user").change(function(){
	if (!$("#chk-subscribe-user").prop("checked")) $("#slct-import-order-owner").val("");
});
$("#btn-import-order").click(function(){
	var a = $("orders-to-import > order.selected");
	var o = [];
	var r = [];
	a.each(function(ind, value){
		o.push($(value).attr("number"));
		r.push(1);
	});
	sendDataToNavi("apiImportOrder", {
		orders: o, 
		routes: r,
		subscribe_me: $("#chk-subscribe-me").prop("checked"),
		subscribe_user: $("#slct-import-order-owner").val()?$("#slct-import-order-owner").val():undefined,
		message_text: $("#text-import-order-text").val()
	}, function (data, status) {
        var ls = recieveDataFromNavi(data, status);
        if (ls && ls.result=='OK') {
			updateAllOrders();
			showInformation("Orders were imported");
        }
	});
});
if (NaviFactory.users) {
	$("#slct-import-order-owner").html("");
	$("#slct-import-order-owner").append('<option value="">Nobody</option>');
	for (var username in NaviFactory.users) {
		$("#slct-import-order-owner").append('<option value="'+username+'">'+username+'</option>');
	}
}

</script>

