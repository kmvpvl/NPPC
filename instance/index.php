<?php include "header.php"?>
<script src="naviNPPC.js"></script>
<script src="ORMNavi.js"></script>
<nav class="navbar navbar-expand-sm navbar-dark bg-dark ml-0">
	<a class="navbar-brand" href="#">My factory
	</a>
	<span id="messages-popup"></span>
	<!--button type="button" class="btn btn-success">Refresh</button-->
	<button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarSupportedContent" aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation">
		<span class="navbar-toggler-icon"></span>
	</button>
	<div class="collapse navbar-collapse" id="navbarSupportedContent">
	<ul class="navbar-nav mr-auto">
		<li class="nav-item active">
			<a class="nav-link" instance="factory.php" id="menuFactory" data-toggle="collapse" data-target=".navbar-collapse.show">Factory</a>
		</li>
		<li class="nav-item" >
			<a class="nav-link" instance="orders.php" id="menuOrders" data-toggle="collapse" data-target=".navbar-collapse.show">Orders</a>
		</li>
		<li class="nav-item dropdown">
			<a class="nav-link dropdown-toggle" href="#" id="navbarDropdown" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Master Data</a>
			<div class="dropdown-menu" aria-labelledby="navbarDropdown">
				<a class="dropdown-item" href="#">Factory, workcentres, routes</a>
				<a class="dropdown-item" href="#">Products</a>
				<a class="dropdown-item" href="#">Customers</a>
				<a class="dropdown-item" href="#">Suppliers</a>
				<div class="dropdown-divider"></div>
				<a class="dropdown-item" href="#">Users</a>
				<a class="dropdown-item" href="#">Settings</a>
			</div>
		</li>
	</ul>
	<ul class="navbar-nav lr-auto">
		<li class="nav-item dropdown">
			<a class="nav-link dropdown-toggle" href="#" id="navbarDropdown" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">David Rhuxel</a>
			<div class="dropdown-menu" aria-labelledby="navbarDropdown">
				<a class="dropdown-item" href="#">My settings</a>
				<a class="dropdown-item" href="#">My subscriptions</a>
				<a class="dropdown-item" href="#">Logout</a>
			</div>
		</li>
	</ul>
	</div>
</nav>
<instance>
</instance>
<messages>
<messages-toolbar>
<button type="button" class="ml-2 mb-1 close" messages="collapse">&times;</button>
<input id="edt-search" type="text" placeholder="Search message..."></input>
</messages-toolbar>
<messages-container>
</messages-container>
<message-template>
<div class="input-group">
  <div class="input-group-prepend">
  <span class="input-group-text">Text</span>
  <select class="custom-select" id="message_type">
		<option value="INFO">info</option>
		<option value="WARNING">warning</option>
		<option value="CRITICAL">critical</option>
	</select>
  </div>
  <textarea id="message_text" class="form-control" aria-label="With textarea" rows="1"></textarea>
  <div class="input-group-append">
	  <button id="btn-send-message" class="btn btn-outline-secondary" type="button">Send</button>
  </div>
</div>
</message-template>    
<messages-navigator>
	<span>By order</span>
	<span>By user</span>
	<span>Subscription</span>
</messages-navigator>
</messages>
<form id="loginform">
	<div class="container">
		<label for="username">User name</label>
		<input type="text" placeholder="Enter Username" id="username" name="username" required value="David Rhuxel">
		<label for="password">Password</label>
		<input type="password" placeholder="Enter Password" id="password" required value="*******"></input>
		<label for="factory">Factory</label>
		<input type="text" placeholder="Enter factory" id="factory" required value="example2"></input>
		<label for="timezone">Timezone</label>
		<select id="timezone" type="select"><option value="+0300" default="default">Moscow</option><option value="+0400">Samara</option></select>
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
<div id="informationMessage" class="alert alert-success">
    <span></span>
</div>
<script>
function collapseMessages() {
    $('messages').hide();
}
$(document).ready (function (){
	$(window).resize(function() {
		$('instance').css('height', $(window).height()-$('instance').position().top + "px");
		$("#loadingSpinner").offset({
			top: ($('body').innerHeight() - $("#loadingSpinner").outerHeight()) / 2, 
			left: ($('body').innerWidth() - $("#loadingSpinner").outerWidth()) / 2
		});
	});
	tryLogin();
	ORMNaviFactory.updateWorkloads();
	updateMessages();
	collapseMessages();
	$("#messages-popup").on('click', function() {
		$('messages').show();
		scrollMessages();
	});
	$(window).resize();
})

$("#btn-send-message").on('click', function () {
	//debugger;
	ORMNaviMessage.send($("#message_text").val(), $("#message_type").val());
})

$('messages messages-toolbar button[messages="collapse"]').on('click', function (event) {
	collapseMessages();
	event.stopPropagation();
})

function clearInstance() {
	$("instance").html("");
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
	$("#errorLoadingMessage").offset({
		left: 0,
		top: ($('body').innerHeight() - $("#errorLoadingMessage").outerHeight())/2
	});
}
function showLoading() {
	$("#errorLoadingMessage").hide();
	$("#loadingSpinner").show();
}

function scrollMessages(){
	if ($("messages messages-container unread-separator").length) {
		$('messages messages-container').animate({scrollTop: $("messages messages-container unread-separator").position().top+$("messages messages-container").scrollTop()-$("messages messages-container unread-separator").outerHeight()*2 }, 1000);
	} else {
		// scroll to bottom
		$('messages messages-container').animate({scrollTop: $("messages messages-container")[0].scrollHeight}, 1000);
	}
}

function updateMessages() {
	sendDataToNavi("apiGetMessages", undefined, 
	function(data, status) {
		//debugger;
		$("messages messages-container").html('');
		hideLoading();
		switch (status) {
			case "success":
				ls = JSON.parse(data);
				var unread_count = 0;
				for (ind in ls.data) {
					if (!(ls.data[ind].read_time || ls.data[ind].from == $("#username").val())) unread_count++;
					$("messages messages-container").prepend('<message message_id="'+ls.data[ind].id+'" read="'+(ls.data[ind].read_time || ls.data[ind].from == $("#username").val()?"1":"0")+'" in="'+(ls.data[ind].from != $("#username").val()?"1":"0")+'"/>');
					m = new ORMNaviMessage(ls.data[ind]);
					if (!(ls.data[ind].read_time || ls.data[ind].from == $("#username").val())) {
						if ($("messages messages-container unread-separator").length) $("messages messages-container unread-separator").remove();
						$("messages messages-container").prepend('<unread-separator>Unread messages</unread-separator>');	
					}
				}
				if (unread_count)	{
					$("#messages-popup").html(unread_count+" messages");
				} else {
					$("#messages-popup").html("No new messages");
				}
				scrollMessages();
				$('messages messages-container message[read="0"]').prepend('<button type="button" class="ml-2 mb-1 close" message="collapse">&times;</button>');
				$('message button[message="collapse"]').on ('click', function (event) {
					$(this).parent()[0].ORMNaviMessage.dismiss();
					updateMessages();
				})
				break;
			default:
				;
		}
	});
}

function hideLoading() {
	$("#loadingSpinner").hide();
} 
function showInformation(text) {
	$("#informationMessage > span").html(text);
	$("#informationMessage").show();
	$("#informationMessage").offset({
		left: 0,
		top: ($('body').innerHeight() - $("#informationMessage").outerHeight())/2
	});
	setTimeout(function() {
		$("#informationMessage").hide();
	}, 1500);
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
				$("instance").html(data);
				setInterval( function () {
					updateMessages();
					ORMNaviFactory.updateWorkloads();
				}, 60000);
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

$("a[instance]").on ('click', function (event) {
	showLoading();
	var p = $.post(event.target.attributes["instance"].value,
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
				$("instance").html(data);
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

function workcenter(_id, _ordhighlight = undefined) {
	showLoading();
	var p = $.post("workcenter.php",
	{
		username: $("#username").val(),
		password: $("#password").val(),
		factory:  $("#factory").val(),
		language: $("#language").val(),
		timezone: $("#timezone").val(),
		highlight: _ordhighlight,
		workcenter: _id
	},
	function(data, status){
		hideLoading();
		switch (status) {
			case "success":
				$("instance").html(data);
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

function order(_id) {
	showLoading();
	var p = $.post("order.php",
	{
		username: $("#username").val(),
		password: $("#password").val(),
		factory:  $("#factory").val(),
		language: $("#language").val(),
		timezone: $("#timezone").val(),
		order: _id
	},
	function(data, status){
		hideLoading();
		switch (status) {
			case "success":
				$("instance").html(data);
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

function road(_id, _ordhighlight = undefined) {
	showLoading();
	var p = $.post("roads.php",
	{
		username: $("#username").val(),
		password: $("#password").val(),
		factory:  $("#factory").val(),
		language: $("#language").val(),
		timezone: $("#timezone").val(),
		highlight: _ordhighlight,
		road: _id
	},
	function(data, status){
		hideLoading();
		switch (status) {
			case "success":
				$("instance").html(data);
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
<div class="modal fade" id="dlgOrderModal" tabindex="-1" role="dialog" aria-labelledby="dlgOrderModalLongTitle" aria-hidden="true">
  <div class="modal-dialog" role="document">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="dlgOrderModalLongTitle">Order information</h5>
        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
          <span aria-hidden="true">&times;</span>
        </button>
      </div>
      <div class="modal-body">
        ...
      </div>
      <div class="modal-footer">
	  <button type="button" class="btn btn-success" data-dismiss="">Update Estimated</button>
	  <button type="button" class="btn btn-success" data-dismiss="">Update Plan</button>
        <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
      </div>
    </div>
  </div>
</div>
<?php include "footer.php"?>
