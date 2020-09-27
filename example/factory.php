<?php include "header.php"?>
<script src="naviNPPC.js"></script>
<?php include "menu.php"?>
<?php
//echo phpversion();
if (!$z = simplexml_load_file('factory.xml')) die ("Factory XML is wrong!");

assert ($z->getName() != "factory", "Factory XML is wrong!: root tag must be 'factory' but " . $z->getName());
//var_dump($z->attributes());
$map_img = $z["img"];
$map_coords = $z["map"];
$map_name = $z["name"];
?>
<script>
var map;
$(document).ready(function(){
	$('[data-toggle="tooltip"]').tooltip();   
	$(window).resize();
	$(".navitem, .active").removeClass("active");
	$("#menuFactory").addClass("active");
	$(".navbar-brand").text("FACTORY");
})
</script>
<?php
$resize_add = "";
function drawWorkcenter($_wcxml){
?>
<svg id="<?=$_wcxml['id']?>" width="0" height="0" data-toggle="tooltip" class="workcenter" title="<?=((string) $_wcxml).trim()?>">
<rect width="100%" height="100%" class="workcenter" />
</svg>
<?php
	global $resize_add;
	$resize_add .= "loc = '" . $_wcxml['location'] . "'.split(';');\n";
	$resize_add .= "wcx = document.getElementById('fimg').offsetLeft + map.LAT2X(loc[0].split(',')[0]);\n";
	$resize_add .= "wcw = map.LAT2X(loc[1].split(',')[0]) - map.LAT2X(loc[0].split(',')[0]);\n";
	$resize_add .= "wcy = document.getElementById('fimg').offsetTop + map.LNG2Y(loc[0].split(',')[1]);\n";
	$resize_add .= "wch = map.LNG2Y(loc[1].split(',')[1]) - map.LNG2Y(loc[0].split(',')[1]);\n";
	$resize_add .= "document.getElementById('" . $_wcxml['id'] . "').style.left = wcx + 'px';\n";
	$resize_add .= "document.getElementById('" . $_wcxml['id'] . "').style.top = wcy + 'px';\n";
	$resize_add .= "document.getElementById('" . $_wcxml['id'] . "').setAttribute('width', wcw + 'px');\n";
	$resize_add .= "document.getElementById('" . $_wcxml['id'] . "').setAttribute('height', wch + 'px');\n";
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
$(window).resize(function() {
	wth = document.getElementById("fimg").offsetWidth;
	hgh = document.getElementById("fimg").offsetHeight;
	lr = "<?=$map_coords?>";
	map = new nppcMap(lr, wth, hgh);
	<?=$resize_add?>
	$("#pwh-1 > .workcenter").addClass("wc-damaged");
	$("#swh-2 > .workcenter").addClass("wc-damaged");
	$("#pwh-2 > .workcenter").addClass("wc-success");
	$('#toast1').toast('show');
	$('#toast2').toast('show');
	$('#toast3').toast('show');
})
</script>
<img id="fimg" style="max-width: 100%;height: auto;" src="<?=$map_img?>"></img>
	<div class="row mt-0">
		<div class="col-sm-6">
  <div class="toast fade show" data-autohide="false" id="toast1">
    <div class="toast-header">
      <strong class="mr-auto text-danger">Ready shafts warehouse</strong>
      <small class="text-muted">5 mins ago</small>
      <button type="button" class="ml-2 mb-1 close" data-dismiss="toast">&times;</button>
    </div>
    <div class="toast-body">
Stockman: Not enough places for ready shafts. Workshop will stop in 30 min
    </div>
  </div>
  <div class="toast fade show" data-autohide="false" id="toast3">
    <div class="toast-header">
      <strong class="mr-auto text-danger">Assembly workshop warehouse</strong>
      <small class="text-muted">just now</small>
      <button type="button" class="ml-2 mb-1 close" data-dismiss="toast">&times;</button>
    </div>
    <div class="toast-body">
Stockman: Supply of shats has stopped. Assembly wil stop in 2 hour
    </div>
  </div>
		</div>
		<div class="col-sm-6">
  <div class="toast fade show" data-autohide="false" id="toast2">
    <div class="toast-header">
      <strong class="mr-auto text-success">Ready whellpairs warehouse</strong>
      <small class="text-muted">1 mins ago</small>
      <button type="button" class="ml-2 mb-1 close" data-dismiss="toast">&times;</button>
    </div>
    <div class="toast-body">
Quality check: Order #2 ready to upload
    </div>
  </div>
		</div>
	</div>
<div id="routedesc"></div>
<?php include "footer.php"?>
