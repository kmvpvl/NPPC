<?php
include "checkORMNavi.php";
$road_name = $_POST["data"]["road"];
$road = $factory->getRoadInfo($road_name);
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
		hideLoading();
		switch (status) {
			case "success":
                $("income").html("");
                $("outcome").html("");
                $("#btnOrderMove").hide();
                $("#btnOrderInfo").hide();
                ls = JSON.parse(data);
				//debugger;
                for (ind in ls.data['<?=$wc_from?>']) {
                    o = ls.data['<?=$wc_from?>'][ind];
					var b = ORMNaviOrder.getBucket(o, '<?=$wc_from?>');
					$('income').append('<order class="brief" number="'+o.number+'" assign="'+b.assign+'" full="'+o.fullset+'"/>');
                    ot = new ORMNaviOrder(o);
                }
                for (ind in ls.data['<?=$wc_to?>']) {
                    o = ls.data['<?=$wc_to?>'][ind];
					var b = ORMNaviOrder.getBucket(o, '<?=$wc_to?>');
					$('outcome').append('<order class="brief" number="'+o.number+'" assign="'+b.assign+'" full="'+o.fullset+'"/>');
                    ot = new ORMNaviOrder(o);
                }
                if (ORMNaviCurrentOrder) $('order[number="'+ORMNaviCurrentOrder+'"]').addClass("highlight");
                $("order[number]").on('click', function() {
                    //debugger;
                    var n = $(this).attr("number");
                    $("order[number]").removeClass("selected");
                    if ($('order[number="'+n+'"]').hasClass("selected")) $('order[number="'+n+'"]').removeClass("selected");
                    else $(this).addClass("selected");
                    if ($("income > order[number].selected").length == 1 || 
                    $("processing > order[number].selected").length == 1) {
                        $("#btnOrderMove").show();
                        $("#btnOrderMove").css({
                            left: $("order[number].selected").position().left+$("#btnOrderInfo").outerWidth()+'px',
    						top: $("order[number].selected").position().top+$("order[number].selected").outerHeight()+'px'
                        });
                    } else {
                        $("#btnOrderMove").hide();
                    }
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
    });
}
updateOrders();
$("#btnOrderMove").on("click", function(){
    if ($("order[number].selected").length == 1) {
        var a = $("order[number].selected").attr("assign");
        ORMNaviCurrentOrder = $("order[number].selected").attr("number")
        sendDataToNavi("apiMoveAssignToNextWorkcenter", {assign: a}, 
        function(data, status) {
            hideLoading();
            //debugger;
            switch (status) {
                case "success":
                    updateOrders();
                    break;
                default:
                    ;
            }
        });
    }
});

$("#btnOrderInfo").on('click', function(){
    if ($("order[number].selected").length == 1) {
        var order = $("order[number].selected").attr("number");
        modalOrderInfo(order);
    }
});
</script>
<orders_in_road>
    <input id="edt-search" type="text" class="form-control" placeholder="Search orders..."></input>
    <span></span>
    <span class="bucket"><b><?=$wc_from_desc?></b> (ord, due, est, plan)</span>
    <span class="bucket"><b><?=$wc_to_desc?></b> (ord, due, est, plan)</span>
    <income></income>
    <outcome></outcome>
</orders_in_road>
<span id="btnOrderInfo"><i class="fa fa-info" aria-hidden="true"></span>
<span id="btnOrderMove"><i class="fa fa-arrow-right" aria-hidden="true"></i></span>
