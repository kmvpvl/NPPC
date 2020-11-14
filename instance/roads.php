<?php
include "checkUser.php";
$road = $navi->getRoadInfo($_POST["road"]);
$brand = trim((string)$road["id"] . ": " . (string)$road["from"]. "-" . (string)$road["to"]);
//var_dump($road);
?>
<?php
$bucks = [(string)$road["from"], (string)$road["to"]];
//echo $brand;
?>
<script>
$(".nav-link.active").removeClass("active");
$("#menuWorkcenter").addClass("active");
$(".navbar-brand").text("<?= $brand ?>");
drawRoads();
drawMessages();

function roadsResize() {
}
function messageCenterResize() {
	if (typeof(resizeMessageCenter) == "function") resizeMessageCenter();	
}

function resizeRoadsContentAll() {
    roadsResize();
    messageCenterResize();
}

$(window).on ('resize', resizeRoadsContentAll);

//resizeWorkcenterContentAll();

function drawRoads() {
}

function drawMessages() {
    $("#messageCenter").html = '';
	showLoading();
	var p = $.post("drawMessages.php",
	{
		username: $("#username").val(),
		factory:  $("#factory").val(),
		password: $("#password").val(),
		language: $("#language").val(),
		timezone: $("#timezone").val()
	},
	function(data, status){
		hideLoading();
		switch (status) {
			case "success":
				$("#messageCenter").html(data);
				resizeMessageCenter();	
				break;
			default:
                ;
		}
	});
	p.fail(function(data, status) {
		hideLoading();
		switch (data.status) {
			case 401:
				clearInstance();
				showLoginForm();
				showLoadingError(data.status + ": " + data.statusText + ". " + data.responseText);
				break;
			default:				
				showLoadingError(data.status + ": " + data.statusText + ". " + data.responseText);
		}
	})
}

$("[assign]").on('click', function (event){
    $(".active[assign]").removeClass("active");
    var c = $("[assign = " + event.currentTarget.attributes["assign"].value + "]");
    c.addClass("active");
    $("#btn-move-assign").css('left',  c.position().left + c.outerWidth() - $("#btn-move-assign").outerWidth() + "px");
    $("#btn-move-assign").css('top',  c.position().top  + "px");
    if (c.attr("wc") == '<?=$road["from"]?>') $("#btn-move-assign").show();
    else $("#btn-move-assign").hide();
    
    $("#btn-order-info").css('left',  c.position().left + "px");
    $("#btn-order-info").css('top',  c.position().top  + "px");
    $("#btn-order-info").show();
});
$("#btn-move-assign").on("click", function(){
	showLoading();
	var p = $.post("apiMoveAssignToNextWorkcenter.php",
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
			    road("<?=$_POST["road"]?>");
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
$("#btn-order-info").on("click", function(){
    order($(".active[assign]").attr("order_number"));
});
<?php
if (isset($_POST["highlight"])) {
?>
$("number:contains('<?=$_POST["highlight"]?>')").css('animation', "order-highlight 2s 100");
<?php
}
?>

</script>
<button id="btn-move-assign">[move]</button>
<button id="btn-order-info">[info]</button>
<div class="input-group mb-3">
	<input type="text" class="form-control" placeholder="Search orders...">
	<div class="input-group-append">
  		<button class="btn btn-success" type="submit">Go</button> 
	</div>
</div>
<?php
    //var_dump($bucks);
    $x = $navi->getRoadAssigns((string)$road["from"], (string)$road["to"]);
    //var_dump($x);
?>
<div class="row ml-0 mr-0">
    <?php 
    foreach ($bucks as $b) { 
    ?>
	<div class="col-sm-6 cell-header"><?= $b ?></div>
<?php 
    }
?>
</div>
<div class="row ml-0 mr-0">
    <?php 
    $i = 0;
    while (TRUE) {
        $last = TRUE;
        foreach ($bucks as $b){
            $c = $x[$b];
            if ($i < count($c)-1) $last = FALSE;
            if ($i < count($c)) {
            $xml_order = order_db_string($c[$i]);
    ?>
	<div wc="<?=$b?>" assign="<?=$c[$i]["id"]?>" class="col-sm-6 cell-data" order_number="<?= $c[$i]["number"]?>">
	<?=$xml_order?>
	</div>
    <?php 
            } else {
    ?>
	<div class="col-sm-6 cell-data">&nbsp;</div>
    <?php 
            }
        }
        if ($last) break;
        $i++;
    }
    ?>
</div>
<div id="messageCenter" class="messageCenter popdown">
</div>