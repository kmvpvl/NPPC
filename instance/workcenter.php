<?php
include "checkUser.php";
$brand = trim((string)$navi->getWorkcenterInfo($_POST["workcenter"]));
//var_dump($_POST["highlight"]);
?>
<script>
$(".nav-link.active").removeClass("active");
$("#menuWorkcenter").addClass("active");
$(".navbar-brand").text("<?= $navi->factoryName . ": " . $brand ?>");
drawWorkcenter();
function workcenterResize() {
	$("#workcenter-div").outerHeight("100%");
    $(".content-div").css('height', $("#workcenter-div").outerHeight() - $(".content-div").offset().top + "px");
}


$(window).on ('resize', workcenterResize());
workcenterResize();


function drawWorkcenter() {
}


$("[assign]").on('click', function (event){
    $(".active[assign]").removeClass("active");
    var c = $("[assign = " + event.currentTarget.attributes["assign"].value + "]");
    c.addClass("active");
    
    $("#btn-move-assign").css('left',  c.position().left + c.outerWidth() - $("#btn-move-assign").outerWidth() + "px");
    //debugger;
    $("#btn-move-assign").css('top',  $("#content-div").scrollTop() + c.position().top  + "px");
    if (c.attr("full") == '1' && c.attr("bucket") != 'OUTCOME')  $("#btn-move-assign").show();
    else $("#btn-move-assign").hide();
    
    $("#btn-order-info").css('left',  c.position().left + "px");
    $("#btn-order-info").css('top',  c.position().top  + "px");
    $("#btn-order-info").show();

});

$("#btn-order-info").on("click", function(){
    order($(".active[assign]").attr("order_number"));
});

$("#edt-search").on("change", function() {
    if("" != $("#edt-search").val()) {
        
        //debugger;
        $("[assign] > order").each(function () {
            $(this).hide();
        });
        cc = $("order > number:contains('" + $("#edt-search").val() + "')");
        cc.each(function (value) {
            $(this).parent().show();
        });
    } else {
        $("[assign] > order").each(function () {
            $(this).show();
        });
    };
})

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
			    workcenter("<?=$_POST["workcenter"]?>");
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
<?php
if (isset($_POST["highlight"])) {
?>
$("number:contains('<?=$_POST["highlight"]?>')").css('animation', "order-highlight 2s 100");
<?php
}
?>
</script>
<?php
$bucks = $navi->getWorkcenterAssigns($_POST["workcenter"]);
//var_dump($bucks);
//echo $brand;
?>
<div id="workcenter-div">
<div class="input-group mb-3">
	<input id="edt-search" type="text" class="form-control" placeholder="Search orders...">
</div>
<div class="row ml-0 mr-0">
    <?php 
    foreach ($bucks as $b => $c) { 
    ?>
	<div class="col-sm-4 cell-header"><?= $b ?></div>
    <?php 
    }
    ?>
</div>
<div class="content-div">
<button id="btn-move-assign">[move]</button>
<button id="btn-order-info">[info]</button>
    <?php 
    $i = 0;
    while (TRUE) {
?>
<div class="row  ml-0 mr-0">
<?php
    $last = TRUE;
        foreach ($bucks as $b => $c){
            if ($i < count($c)-1) $last = FALSE;
            if ($i < count($c)) {
            $xml_order = order_db_string($c[$i]);
    ?>
	<div bucket="<?=$b?>" assign="<?=$c[$i]["id"]?>" full="<?=(($c[$i]["fullset"] != "1") ? "0" : "1")?>" class="col-sm-4 cell-data" order_number="<?= $c[$i]["number"]?>"><?= ($c[$i]["fullset"] != "1") ? "(not full)" : ""?>
	<?=$xml_order?>
	</div>
    <?php 
            } else {
    ?>
	<div class="col-sm-4 cell-data">&nbsp;</div>
    <?php 
            }
        }
        if ($last) break;
        $i++;
?>
</div>
<?php
    }
    ?>
</div>
</div>
</div>
