<?php include "header.php"?>
<?php include "menu.php"?>
<script>
$(document).ready(function() {
	$(window).resize();
	$(".navitem, .active").removeClass("active");
	$("#menuOrders").addClass("active");
	$(".navbar-brand").text("ORDERS");
})

$(window).resize(function() {
	$('#content-div').css('height', $(window).height()-$('#content-div').offset().top);
})
</script>
	<div class="row mt-0">
		<div class="col-sm-3 cell-header">Order</div>
		<div class="col-sm-2 cell-header">Deadline</div>
		<div class="col-sm-2 cell-header">Expected</div>
		<div class="col-sm-1 cell-header">Lag</div>
		<div class="col-sm-1 cell-header">Status</div>
		<div class="col-sm-3 cell-header">Customer</div>
	</div>
<div id="content-div">
<?php for ($i = 0; $i < 12; $i++) {?>
	<div class="row">
		<div class="col-sm-3 cell-data"><a href="orderTracking.php" class="badge badge-secondary">
		1, Wheel pair
		</a>
		</div>
		<div class="col-sm-2 cell-data">12/15/20</div>
		<div class="col-sm-2 cell-data">11/30/20</div>
		<div class="col-sm-1 cell-data">-</div>
		<div class="col-sm-1 cell-data">
		<div class="btn-group">
		  <button type="button" class="badge badge-warning dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
<i class="fa fa-pause"></i>
		  </button>
		  <div class="dropdown-menu">
		    <a class="dropdown-item" href=""><i class="fa fa-play"></i>Continue</a>
		    <a class="dropdown-item" href=""><i class="fa fa-stop"></i>Abandon</a>
		    <a class="dropdown-item" href=""><i class="fa fa-pause"></i>Pause</a>
		    <a class="dropdown-item" href=""><i class="fa fa-pause"></i>Merge</a>
		  </div>
		</div>
		</div>
		<div class="col-sm-3 cell-data-left">Chamomile LTD</div>
	</div>
<?php } ?>
</div>
<?php include "footer.php"?>
