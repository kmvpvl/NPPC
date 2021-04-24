<?php
include "checkORMNavi.php";
$factory->hasRoleOrDie(["IMPORT_ORDER"]);
?>
<script>
$(".nav-link.active").removeClass("active");
$(".nav-item.active").removeClass("active");
$("#menuOrders").addClass("active");
$(".navbar-brand").text(NaviFactory.name + ": Orders");
function ordersUpdated(data, status) {
	$("orders_to_import").html("");
	$("orders_inprocess").html("");
	var ls = recieveDataFromNavi(data, status);
	if (ls && ls.result=='OK') {
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
				$("#btnsPriority").show();
				$("#btnsPriority").css({
					left: ($("order[number].selected").position().left+$("#btnOrderInfo").outerWidth())+'px',
					top: $("order[number].selected").position().top+$("order[number].selected").outerHeight()+'px'
				});
			} else {
				$("#btnsPriority").hide();
				$("#btnOrderInfo").hide();
			}
		});
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
<span id="btnOrderInfo"><i class="fa fa-info-circle" aria-hidden="true"></i></span>
<span id="btnsPriority"><i id="btnPriorityUp" class="fa fa-arrow-circle-up" aria-hidden="true"></i><i id="btnPriorityDown" class="fa fa-arrow-circle-down" aria-hidden="true"></i></span>
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
	var a = $("orders_to_import > order.selected");
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
$('#btnPriorityUp').click(function(){
    if ($("order[number].selected").length == 1) {
        var order = $("order[number].selected").attr("number");
		sendDataToNavi('apiIncOrderPriority', {order: order, delta: 1}, function(data, status){
			var ls = recieveDataFromNavi(data, status);
			if (ls && ls.result=='OK') {
				updateAllOrders();
				showInformation("Priority was changed!");
			}
		});
    }
});
$('#btnPriorityDown').click(function(){
    if ($("order[number].selected").length == 1) {
        var order = $("order[number].selected").attr("number");
		sendDataToNavi('apiIncOrderPriority', {order: order, delta: -1}, function(data, status){
			var ls = recieveDataFromNavi(data, status);
			if (ls && ls.result=='OK') {
				updateAllOrders();
				showInformation("Priority was changed!");
			}
		});
    }
});
if (NaviFactory.users) {
	$("#slct-import-order-owner").html("");
	$("#slct-import-order-owner").append('<option value="">Nobody</option>');
	for (var username in NaviFactory.users) {
		$("#slct-import-order-owner").append('<option value="'+username+'">'+username+'</option>');
	}
}

</script>

