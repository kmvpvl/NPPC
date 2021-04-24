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
        ls = recieveDataFromNavi(data, status);
        $("income").html("");
        $("processing").html("");
        $("outcome").html("");
        $("#btnOrderMove").hide();
        $("#btnOrderInfo").hide();
        for (ind in ls.data) {
            o = ls.data[ind];
            //debugger;
            var b = ORMNaviOrder.getBucket(o, '<?=$workcenter?>');
            if (b) {
                $(b.bucket).append('<order class="brief" number="'+o.number+'" assign="'+b.assign+'" full="'+(b.fullset=='1'?"1":"0")+'" operation="'+b.operation+'"/>');
            } else {
            }
            ot = new ORMNaviOrder(o);
        }
        $('order[full="0"]').prepend('<span class="order-bage">partly</span>');
        if (ORMNaviCurrentOrder)
            $('order[number="'+ORMNaviCurrentOrder+'"]').addClass("highlight");
        $("order[number]").on('click', function() {
            //debugger;
            var n = $(this).attr("number");
            $("order[number]").removeClass("selected");
            if ($('order[number="'+n+'"]').hasClass("selected")) $('order[number="'+n+'"]').removeClass("selected");
            else $('order[number="'+n+'"]').addClass("selected");
            if ( ($("income > order[number].selected").length == 1 ||
            $("processing > order[number].selected").length == 1) &&
            $("order[number].selected").attr("full")=="1") {
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
    });
}
updateOrders();
$("#btnOrderMove").on("click", function(){
    if ($("order[number].selected").length == 1) {
        var a = $("order[number].selected").attr("assign");
        ORMNaviCurrentOrder = $("order[number].selected").attr("number")
        sendDataToNavi("apiMoveAssignToNextBucket", {assign: a}, 
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
<orders_in_workcenter>
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
</orders_in_workcenter>
<span id="btnOrderInfo"><i class="fa fa-info-circle" aria-hidden="true"></i></span>
<span id="btnOrderMove"><i class="fa fa-arrow-circle-right" aria-hidden="true"></i></span>
