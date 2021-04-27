<?php
include "checkORMNavi.php";
$road_name = $_POST["data"]["road"];
$road = $factory->getRoadInfo($road_name);
$factory->hasRoleOrDie(["MOVE_ORDER_ROAD%".$road_name]);
$brand = trim($road);
$wc_from = (string)$road["from"];
$wc_to = (string)$road["to"];
$wc_from_desc = trim($factory->getWorkcenterInfo($wc_from));
$wc_to_desc = trim($factory->getWorkcenterInfo($wc_to));
?>
<script>
$(".nav-link.active").removeClass("active");
$(".navbar-brand").text("<?= $factory->description . ": " . $brand ?>");

function updateOrders() {
    sendDataToNavi("apiGetRoadOrders", {road: '<?=$road_name?>'}, 
    function(data, status){
        var ls = recieveDataFromNavi(data, status);
        if (ls && ls.result=='OK') {
            $("income").html("");
            $("outcome").html("");
            for (const o of ls.data['<?=$wc_from?>']) {
                var $o = $('<order class="brief"/>');
                var ot = new ORMNaviOrder(o, $o);
                ot.showOperation(null, false);
                var h = ot.getHistoryByWorkcenterName('<?=$wc_from?>');
                if (h) {
                    $o.attr({'assign': h.id,
                        'full': h.fullset=='1'?"1":"0",
                        'operation': h.operation});
                    $('income').append($o);
                    ot.showOperation(['info', 'next', 'priority-up', 'priority-down', 'defect'], true);
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
                            sendDataToNavi("apiMoveAssignToNextWorkcenter", {assign: a}, 
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
            for (const o of ls.data['<?=$wc_to?>']) {
                var $o = $('<order class="brief"/>');
                var ot = new ORMNaviOrder(o, $o);
                ot.showOperation(null, false);
                var h = ot.getHistoryByWorkcenterName('<?=$wc_to?>');
                if (h) {
                    $o.attr({'assign': h.id,
                        'full': h.fullset=='1'?"1":"0",
                        'operation': h.operation});
                    $('outcome').append($o);
                    ot.showOperation(['info','defect'], true);
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
                            sendDataToNavi("apiMoveAssignToNextWorkcenter", {assign: a}, 
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
            if (ORMNaviCurrentOrder) $('order[number="'+ORMNaviCurrentOrder+'"]').addClass("highlight");
            $("order[number]").on('click', function() {
                //debugger;
                var n = $(this).attr("number");
                $("order[number]").removeClass("selected");
                if ($('order[number="'+n+'"]').hasClass("selected")) $('order[number="'+n+'"]').removeClass("selected");
                else $(this).addClass("selected");
            });
        } 
    });
}
updateOrders();
</script>
<orders-in-road>
    <input id="edt-search" type="text" class="form-control" placeholder="Search orders..."></input>
    <span></span>
    <span class="bucket"><b><?=$wc_from_desc?></b> (ord, due, est, plan)</span>
    <span class="bucket"><b><?=$wc_to_desc?></b> (ord, due, est, plan)</span>
    <income></income>
    <outcome></outcome>
</orders-in-road>
<span id="btnOrderInfo"><i class="fa fa-info-circle" aria-hidden="true"></i></span>
<span id="btnOrderMove"><i class="fa fa-arrow-circle-right" aria-hidden="true"></i></span>
