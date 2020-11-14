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


$("#btn-import-order").on("click", function(){
    $("#dlgModal .modal-body").html($("#dlg-orderImport").html());
    $("#dlgModal [dlg-button='btn-dlgModal-ok']").text("Import");
    $("#dlgModal").modal("show");
})

$("#dlgModal").on("click", "[dlg-button='btn-dlgModal-ok']",function(e) {
    $("#dlgModal").modal("hide");
    var os = new Array();
    $(".active[order][type='INCOME']").each (function () {
        os.push($(this).attr("order"));
    });

	showLoading();
	var p = $.post("apiImportOrder.php",
	{
		username: $("#username").val(),
		password: $("#password").val(),
		factory:  $("#factory").val(),
		language: $("#language").val(),
		timezone: $("#timezone").val(),
		order_number: os,
		user: undefined,
		message: $("#dlgModal #message-text").val()==''? undefined : $("#dlgModal #message-text").val(),
		route: 1
	},
	function(data, status){
		hideLoading();
		switch (status) {
			case "success":
			    //debugger;
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
    //debugger;
    var c = event.currentTarget;
    if (c.classList.contains("active")) {
        c.classList.remove("active");
        $("#income-selected-count").text(Number($("#income-selected-count").text()) - 1);
        $("#btn-import-order").hide();
    } else {
        c.classList.add("active");
        $("#income-selected-count").text(Number($("#income-selected-count").text()) + 1);
        $("#btn-import-order").css('left', c.offsetWidth - $("#btn-import-order").outerWidth() + "px");
        $("#btn-import-order").css('top',  c.offsetTop  + "px");
        $("#btn-import-order").show();
    }
    if (Number($("#income-selected-count").text()) > 0) {
        //debugger;
        //$("#btn-import-orders").show();
        //$("#btn-route-order").show();
    } else {
        //$("#btn-import-orders").hide();
        //$("#btn-route-order").hide();
    }
})
$("[order][type='PROCESSING']").on ('click', function (event) {
    //debugger;
    var c = event.currentTarget;
    if (c.classList.contains("active")) {
        c.classList.remove("active");
        $("#processing-selected-count").text(Number($("#processing-selected-count").text()) - 1);
        $("#btn-update-baseline").hide();
    } else {
        c.classList.add("active");
        $("#processing-selected-count").text(Number($("#processing-selected-count").text()) + 1);
        $("#btn-update-baseline").css('left',  c.offsetWidth - $("#btn-update-baseline").outerWidth() + "px");
        $("#btn-update-baseline").css('top',  c.offsetTop  + "px");
        $("#btn-update-baseline").show();

        $("#btn-order-info").css('left',  c.offsetLeft + "px");
        $("#btn-order-info").css('top',  c.offsetTop  + "px");
        if (Number($("#processing-selected-count").text()) == 1) $("#btn-order-info").show();
        else $("#btn-order-info").hide();
    }
    if (Number($("#processing-selected-count").text()) > 0) {
        //debugger;
        //$("#btn-order-info").hide();
    } else {
    }
})

$("#btn-order-info").on("click", function(event){
    order($(".active[order][type='PROCESSING']").attr("order"));
});

$("[button='info']").on('click', function () {
	showLoading();
	var p = $.post("apiRecalcEstimatedTime.php",
	{
		username: $("#username").val(),
		password: $("#password").val(),
		factory:  $("#factory").val(),
		language: $("#language").val(),
		timezone: $("#timezone").val(),
		order_number: $(".active[order][type='PROCESSING']").attr("order")
	},
	function(data, status){
		hideLoading();
		switch (status) {
			case "success":
			    $("#deb").html(data);
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
$("#edt-search-processing").on("change", function() {
    if("" != $("#edt-search-processing").val()) {
        
        //debugger;
        $("[order][type='PROCESSING'] > order").each(function () {
            $(this).hide();
        });
        cc = $("order > number:contains('" + $("#edt-search-processing").val() + "')");
        cc.each(function (value) {
            $(this).parent().show();
        });
    } else {
        $("[order][type='PROCESSING'] > order").each(function () {
            $(this).show();
        });
    };
})
</script>
<?php
$fs = $navi->getOrdersForImport();
//var_dump($fs);
?>
<div id="deb"></div>
<div class="row ml-0 mr-0">
	<div class="col-sm-6 cell-header">
	    <button>-</button>
	    <input type="text" placeholder="Search...">
	    <button>+</button>
        <button id="btn-route-order">[route]</button>
        <button id="btn-order-info">[info]</button>
	</div>
	<div class="col-sm-6 cell-header">
	    <button>-</button>
	    <input id="edt-search-processing" type="text" placeholder="Search...">
	    <button>+</button>
        <button id="btn-update-baseline">[upd baseline]</button>
        <!--button id="btn-prior-up">[up]</button>
        <button id="btn-prior-down">[down]</button-->
    </span>

	</div>
</div>
<div class="row ml-0 mr-0">
	<div class="col-sm-6 cell-header">INCOME <span id="income-selected-count">0</span> of <?=count($fs["to_import"])?></div>
	<div class="col-sm-6 cell-header">PROCESSING<span id="processing-selected-count">0</span> of <?=count($fs["imported"])?></div>
</div>
<div class="content-div">
<button id="btn-import-order">[assign]</button>
<?php
$iit = (new ArrayObject($fs["to_import"]))->getIterator();
$dit = (new ArrayObject($fs["imported"]))->getIterator();
while ($iit->valid() || $dit->valid()) {
?>
<div class="row ml-0 mr-0">
<?php
    if ($iit->valid()) {
?>
	<div class="col-sm-6 cell-data" type="INCOME" order="<?= $iit->key()?>"><?= $iit->key() . " " . $iit->current()?></div>
<?php
        $iit->next();
    } else {
?>
	<div class="col-sm-6 cell-data">&nbsp;</div>
<?php
    }
    if ($dit->valid()) {
        $order_data = $dit->current();
        $xml_order = order_db_string($order_data);
        //$navi->updateEstimatedTime($navi->getOrderInfo($order_data["number"]));
?>
	<div class="col-sm-6 cell-data" type="PROCESSING" order="<?= $order_data["number"]?>" state="<?= $order_data["state"]?>">
	<?=$xml_order?>
	</div>
<?php
        $dit->next();
    } else {
?>
	<div class="col-sm-6 cell-data">&nbsp;</div>
<?php
    }
?>
</div>
<?php
};
?>
</div>
<div id="dlg-orderImport" style="display:none;">
<div class="form-group">
<label for="recipient-name" class="col-form-label">Recipient:</label>
<input type="text" class="form-control" id="recipient-name">
</div>
<div class="form-group">
<label for="message-text" class="col-form-label">Message:</label>
<textarea class="form-control" id="message-text"></textarea>
</div>
</div>
