<?php include "header.php"?>
<script src="naviNPPC.js"></script>
<?php include "menu.php"?>
<div id="instance-div">
</div>
<form id="loginform">
	<div class="container">
		<label for="username">User name</label>
		<input type="text" placeholder="Enter Username" id="username" name="username" required value="David Rhuxel">
		<label for="password">Password</label>
		<input type="password" placeholder="Enter Password" id="password" required value="*******"></input>
		<label for="factory">Factory</label>
		<input type="text" placeholder="Enter factory" id="factory" required value="example2"></input>
		<label for="timezone">Timezone</label>
		<input id="timezone" type="number" min="-12" max="12" class="digit" value="3"></input>
		<label for="language">Language</label>
		<select id="language" type="select"><option value="en" default="default">EN</option><option value="ru">RU</option></select>
		
		<button id="submitLogin">Login</button>
		<label>
		<input type="checkbox" checked="checked" name="remember"> Remember me</input>
		</label>
	</div>
	
	<div class="container" style="background-color:#f1f1f1">
		<span class="psw">Forgot <a href="">password?</a></span>
	</div>
</form>
<div id="errorLoadingMessage" class="alert alert-danger alert-dismissible">
    <button type="button" class="close" data-dismiss="alert">&times;</button>
    <span></span>
</div>
<div id="loadingSpinner" class="spinner-border"></div>
<script>
$(document).ready (function (){
	$(window).resize();
	tryLogin();
})
$(window).resize(function() {
	$('#instance-div').css('height', $(window).height()-$('#instance-div').offset().top);
	$("#loadingSpinner").offset({
		top: ($('#instance-div').outerHeight() - $("#loadingSpinner").outerHeight()) / 2, 
		left: ($('#instance-div').outerWidth() - $("#loadingSpinner").outerWidth()) / 2
	});
})


function clearInstance() {
	$("#instance-div").html = "";
}
function showLoginForm() {
	$("#loginform").show();
	$("#submitLogin").on ('click', function (){
		tryLogin();
	})
}
function showLoadingError(_text) {
	$("#loadingSpinner").hide();
	$("#errorLoadingMessage > span").html(_text);
	$("#errorLoadingMessage").show();
}
function showLoading() {
	$("#errorLoadingMessage").hide();
	$("#loadingSpinner").show();
}
function hideLoading() {
	$("#loadingSpinner").hide();
} 
function tryLogin() {
	showLoading();
	var p = $.post("factory.php",
	{
		username: $("#username").val(),
		password: $("#password").val(),
		factory:  $("#factory").val(),
		language: $("#language").val(),
		timezone: $("#timezone").val()
	},
	function(data, status){
		hideLoading();
		switch (status) {
			case "success":
				$("#instance-div").html(data);
				break;
			default:
				clearInstance();
				showLoginForm();
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

</script>
<?php include "footer.php"?>
