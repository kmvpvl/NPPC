<?php
include "checkORMNavi.php";
$workcenter = $_POST["data"]["workcenter"];
$factory->hasRoleOrDie(["MOVE_ORDER_WC%".$workcenter]);
$wcInfo = $factory->getWorkcenterInfo($workcenter);
$brand = trim($wcInfo);
?>
<script>
$(".nav-link.active").removeClass("active");
$(".navbar-brand").text(NaviFactory.name+ "<?=": " . $brand ?>");

function updateOrders() {
    sendDataToNavi("apiGetWorkcenterOrders", {workcenter: '<?=$workcenter?>'}, 
    function(data, status){
        var ls = recieveDataFromNavi(data, status);
        if (ls && ls.result=='OK') {
            $("income").html("");
            $("processing").html("");
            $("outcome").html("");
            //debugger;
            for (ind in ls.data) {
                //debugger;
                var o = ls.data[ind];
                var $o = $('<order class="brief"/>');
                var ot = new ORMNaviOrder(o, $o);
				ot.showOperation(null, false);
                var h = ot.getHistoryByWorkcenterName('<?=$workcenter?>');
                if (h) {
                    $o.attr({'assign': h.id,
                        'full': h.fullset=='1'?"1":"0",
                        'operation': h.operation});
                    $(h.bucket).append($o);
                    switch (h.bucket) {
                        case 'INCOME': ot.showOperation(['info', 'next', 'priority-up', 'priority-down', 'defect'], true);
                        if (h.fullset != '1') ot.showOperation('next', false);
                        break;
                        case 'PROCESSING':ot.showOperation(['info', 'next', 'priority-up', 'priority-down', 'defect'], true);
                        if (h.fullset != '1') ot.showOperation('next', false);
                        break;
                        case 'OUTCOME': ot.showOperation(['info', 'defect'], true);
                        break;
                    }
                } else {
                }
				ot.on('operation', function(order, cntxt){
					switch (cntxt.operation){
						case 'info':
							modalOrderInfo(order.number);
							break;
						case 'priority-up':
							break;
						case 'priority-down':
						break;
                        case 'next':
                            var a = order.el.attr("assign");
                            ORMNaviCurrentOrder = order.number;
                            sendDataToNavi("apiMoveAssignToNextBucket", {assign: a}, 
                            function(data, status) {
                                var ls = recieveDataFromNavi(data, status);
                                if (ls && ls.result=='OK') {
                                    updateOrders();
                                }
                            });
                        break;
						default:
					}
				});
            }
            //if (!$('outcome').html()) $('outcome').hide();
            //else $('outcome').show();
            $('order[full="0"]').prepend('<span class="order-bage">partly</span>');
            if (ORMNaviCurrentOrder)
                $('order[number="'+ORMNaviCurrentOrder+'"]').addClass("highlight");
            $("order[number]").on('click', function() {
                var n = $(this).attr("number");
                $("order[number]").removeClass("selected");
                if ($('order[number="'+n+'"]').hasClass("selected")) $('order[number="'+n+'"]').removeClass("selected");
                else $('order[number="'+n+'"]').addClass("selected");
            });
        }
    });
}
updateOrders();


function filterOrders() {
    if ($("#edt-search").val() || $("#slct-operation").val()) {
        $('order[number]').hide();
        $('order'+($("#edt-search").val()?'[number*="'+$("#edt-search").val()+'"]':'')+($("#slct-operation").val()?'[operation="'+$("#slct-operation").val()+'"]':'')).show();
    } else {
        $('order[number]').show();
    }
}
$("#edt-search").change(function(){
    filterOrders();
});
$("#slct-operation").change(function(){
    filterOrders();
});
</script>
<orders-in-workcenter>
    <select class="custom-select" id="slct-operation">
    <option value="">All operations</option>
<?php
    foreach ($wcInfo as $op) {
        echo ('<option value="'.$op["ref"].'">'.$op["ref"].'</option>');
    }
?>
	</select>
    <input id="edt-search" type="text" class="form-control" placeholder="Search orders..."></input>
    <span></span>
    <span class="bucket"><b>INCOME</b> (ord, due, est, plan)</span>
    <span class="bucket"><b>PROCESSING</b> (ord, due, est, plan)</span>
    <span class="bucket"><b>OUTCOME</b> (ord, due, est, plan)</span>
    <income></income>
    <processing></processing>
    <outcome></outcome>
</orders-in-workcenter>
