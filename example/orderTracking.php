<?php include "header.php"?>
<script src="naviNPPC.js"></script>
<?php
//echo phpversion();
if (!$z = simplexml_load_file('factory.xml')) die ("Factory XML is wrong!");

//assert ((string)$z->getName() != "factory", "Factory XML is wrong!: root tag must be 'factory'");
//var_dump($z->attributes());
$map_img = $z["img"];
$map_coords = $z["map"];
$map_name = $z["name"];
?>
<div class="container mt-0">
<h3>Order tracking</h3>
<div class="container-fluid">
	<div class="row">
		<div class="col-2" style="border-left:0px solid;"><b>Order</b></div>
		<div class="col-4" style="border-left:1px solid;"><b>Description</b></div>
		<div class="col-2" style="border-left:1px solid;"><b>Deadline</b></div>
		<div class="col-2" style="border-left:1px solid;"><b>Status</b></div>
		<div class="col-2" style="border-left:1px solid;"><b>Cur. route</b></div>
	</div>
	<div class="row">
		<div class="col-2" style="border-left:0px solid;">1</div>
		<div class="col-4" style="border-left:1px solid;">Wheel pair</div>
		<div class="col-2" style="border-left:1px solid;">11/30/20</div>
		<div class="col-2" style="border-left:1px solid;">In progress</div>
		<div class="col-2" style="border-left:1px solid;">
			<select name="routes" id="routes"></select>
		</div>
	</div>
</div>

<script>
var map;
$(document).ready(function(){
	$('[data-toggle="tooltip"]').tooltip();   
	resize();
	loadRoutes("1");
});

function loadRoutes(orderNum) {
	$.post("apiGetOrderRoutes.php",
	{
		client: 1,
		safetykey: "1",
		lang: "en",
		ntimezone: 3,
		order: orderNum 
	},
	function(data, status){
		switch (status) {
			case "success":
				ans = JSON.parse(data);
				if (ans.result == "OK") {
					ans.data.forEach(function(item, index, arr){
						$("#routes").append(new Option(item.id + ":" + item.workcenter, item.id))
					}); 
				} else {
					alert("Error: " + ans["description"]);
				}
				break;
			default:
				alert("error status: " + status);
		}
	});
}
$("#routes").change(function (){
	$.post("apiGetOrderRoute.php",
	{
		client: 1,
		safetykey: "1",
		lang: "en",
		ntimezone: 3,
		order: $("#routes").val().split(".")[0], 
		route: $("#routes").val().split(".")[1]
	},
	function(data, status){
		switch (status) {
			case "success":
				ans = JSON.parse(data);
				if (ans.result == "OK") {
					$("#routedesc").text(data);
				} else {
					alert("Error: " + ans["description"]);
				}
				break;
			default:
				alert("error status: " + status);
		}
	});
})
</script>
<?php
$resize_add = "";
function drawWorkcenter($_wcxml){
?>
<svg id="<?=$_wcxml->attributes()['id']?>" width="0" height="0" data-toggle="tooltip" class="workcenter" title="<?=((string) $_wcxml).trim()?>">
<rect width="100%" height="100%" class="workcenter" />
</svg>
<?php
	global $resize_add;
	$resize_add .= "loc = '" . $_wcxml->attributes()['location'] . "'.split(';');\n";
	$resize_add .= "wcx = document.getElementById('fimg').offsetLeft + document.getElementById('content-div').offsetLeft + map.LAT2X(loc[0].split(',')[0]);\n";
	$resize_add .= "wcw = map.LAT2X(loc[1].split(',')[0]) - map.LAT2X(loc[0].split(',')[0]);\n";
	$resize_add .= "wcy = document.getElementById('fimg').offsetTop + document.getElementById('content-div').offsetTop + map.LNG2Y(loc[0].split(',')[1]);\n";
	$resize_add .= "wch = map.LNG2Y(loc[1].split(',')[1]) - map.LNG2Y(loc[0].split(',')[1]);\n";
	$resize_add .= "document.getElementById('" . $_wcxml->attributes()['id'] . "').style.left = wcx + 'px';\n";
	$resize_add .= "document.getElementById('" . $_wcxml->attributes()['id'] . "').style.top = wcy + 'px';\n";
	$resize_add .= "document.getElementById('" . $_wcxml->attributes()['id'] . "').setAttribute('width', wcw + 'px');\n";
	$resize_add .= "document.getElementById('" . $_wcxml->attributes()['id'] . "').setAttribute('height', wch + 'px');\n";
	//var_dump($resize_add);
	//var_dump($_wcxml->attributes()["location"]);
	//var_dump($_wcxml);
	foreach ($_wcxml as $wc) {
		switch ( $wc->getName()	) {
			case "workcenter":
				drawWorkcenter($wc);
				break;
		}
	}
}

foreach ($z as $wc) {
	switch ( $wc->getName()	) {
		case "workcenter":
			drawWorkcenter($wc);
			break;
		case "route":
			break;
		default:
			die ("Unexpected tag " . $wc->getName() . " in factory");
	}
} 
?>
<script>
function resize() {
	$('#content-div').css('height', $(window).height()-$('#content-div').offset().top);
	wth = document.getElementById("fimg").offsetWidth;
	hgh = document.getElementById("fimg").offsetHeight;
	lr = "<?=$map_coords?>";
	map = new nppcMap(lr, wth, hgh);
	<?=$resize_add?>
}
</script>
<div id="content-div">
<img id="fimg" style="max-height: 70%;width: auto;" src="<?=$map_img?>"></img>
<h4>Order events</h4>
<div class="container-fluid">
	<div class="row">
		<div class="col-2" style="border-left:1px solid;border-bottom:1px solid;"><b>Date-time</b></div>
		<div class="col-4" style="border-left:1px solid;border-bottom:1px solid;"><b>Event</b></div>
		<div class="col-2" style="border-left:1px solid;border-bottom:1px solid;"><b>Location</b></div>
		<div class="col-4" style="border-left:1px solid;border-bottom:1px solid;"><b>Part or operation</b></div>
	</div>
	<div class="row">
		<div class="col-2" style="border-left:1px solid;border-bottom:1px solid;">10/01/20</div>
		<div class="col-4" style="border-left:1px solid;border-bottom:1px solid;">Order blankshaft finished</div>
		<div class="col-2" style="border-left:1px solid;border-bottom:1px solid;">cwh</div>
		<div class="col-4" style="border-left:1px solid;border-bottom:1px solid;">Blank shaft</div>
	</div>
</div>

</div>
<?php include "footer.php"?>
