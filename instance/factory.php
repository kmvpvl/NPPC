<?php
include "checkORMNavi.php";
?>
<script>
//debugger;
$(".nav-link.active").removeClass("active");
$(".nav-item.active").removeClass("active");
$("#menuFactory").addClass("active");
$(".navbar-brand").text(NaviFactory.name+": Overview");
NaviFactory.draw($('#factoryMap'));
$('[road]').click(function(){
	road($(this).attr("road"));
});
$('[workcenter]').click(function(){
	workcenter($(this).attr('workcenter'));
});
function resizeOn(){
	$('#factoryMap').outerWidth($('instance').width());
	$('#factoryMap').outerHeight($('instance').height()-$('#factoryMap').position().top);
	NaviFactory.draw($('#factoryMap'));
};
</script>
<factory>
<input type="text" class="form-control" placeholder="Search orders or anything..."></input>
<div id="factoryMap"></div>
</factory>