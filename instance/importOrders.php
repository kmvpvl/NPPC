<?php
include "checkUser.php";
?>
<button id="import-orders">Import</button>
<script>
$("#import-orders").on ("click", function(){
	showLoading();
	var p = $.post("apiImportOrder.php",
	{
		username: $("#username").val(),
		password: $("#password").val(),
		factory:  $("#factory").val(),
		language: $("#language").val(),
		timezone: $("#timezone").val(),
		order: "1",
		route: "1"
	},
	function(data, status){
		hideLoading();
		switch (status) {
			case "success":
				$("#instance-div").html(data);
				break;
			default:
				clearInstance();
		hideLoading();
				showLoginForm();
		}
	});
	p.fail(function(data, status) {
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
})
</script>