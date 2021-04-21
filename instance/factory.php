<?php
include "checkORMNavi.php";
?>
<script>
//debugger;
$(".nav-link.active").removeClass("active");
$(".nav-item.active").removeClass("active");
$("#menuFactory").addClass("active");
$(".navbar-brand").text(NaviFactory.name+": Overview");
function redraw() {
	NaviFactory.draw($('#factoryMap'));
	$('[road]').click(function(){
		road($(this).attr("road"));
	});
	$('[workcenter]').click(function(){
		workcenter($(this).attr('workcenter'));
	});
}
function resizeOn(){
	if(!$('#factoryMap').length) return; 
	redraw();
};
redraw();
</script>
<factory>
<input type="text" class="form-control" placeholder="Search orders or anything..."></input>
<span id="factoryMap"></span>
</factory>