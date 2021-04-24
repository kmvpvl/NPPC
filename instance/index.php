<?php include "header.php"?>
<script src="naviNPPC.js"></script>
<script src="ORMNavi.js"></script>
<nav class="navbar navbar-expand-sm navbar-dark bg-dark ml-0">
	<a class="navbar-brand" href="#">
	</a>
	<span id="messages-popup"></span>
	<!--button type="button" class="btn btn-success">Refresh</button-->
	<button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarSupportedContent" aria-controls="navbarSupportedContent" aria-expanded="false" aria-label="Toggle navigation">
		<span class="navbar-toggler-icon"></span>
	</button>
	<div class="collapse navbar-collapse" id="navbarSupportedContent">
	<ul class="navbar-nav mr-auto">
		<li class="nav-item active">
			<a class="nav-link" instance="factory" id="menuFactory" data-toggle="collapse" data-target=".navbar-collapse.show">Factory</a>
		</li>
		<li class="nav-item" >
			<a class="nav-link" instance="orders" id="menuOrders" data-toggle="collapse" data-target=".navbar-collapse.show">Orders</a>
		</li>
		<li class="nav-item dropdown">
			<a class="nav-link dropdown-toggle" href="#" id="navbarDropdown" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">Master Data</a>
			<div class="dropdown-menu" aria-labelledby="navbarDropdown">
				<a class="dropdown-item" href="#">Factory, workcentres, routes</a>
				<a class="dropdown-item" href="#">Products</a>
				<a class="dropdown-item" href="#">Customers</a>
				<a class="dropdown-item" href="#">Suppliers</a>
				<div class="dropdown-divider"></div>
				<a class="dropdown-item" instance="users" id="menuUsers" data-toggle="collapse" data-target=".navbar-collapse.show">Users</a>
				<a class="dropdown-item" href="#">Settings</a>
			</div>
		</li>
	</ul>
	<ul class="navbar-nav lr-auto">
		<li class="nav-item dropdown">
			<a class="nav-link dropdown-toggle" href="" id="menu-user" role="button" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false"></a>
			<div class="dropdown-menu" aria-labelledby="menu-user">
				<a class="dropdown-item" href="#">My settings</a>
				<a class="dropdown-item" href="#">My subscriptions</a>
				<a class="dropdown-item" id="menu-logout" data-toggle="collapse" data-target=".navbar-collapse.show">Logout</a>
			</div>
		</li>
	</ul>
	</div>
</nav>
<instance></instance>
<messages>
<messages-toolbar>
<button type="button" class="ml-2 mb-1 close" messages="collapse">&times;</button>
<input id="edt-message-search" type="text" placeholder="Search message..."></input>
</messages-toolbar>
<messages-container>
</messages-container>
<message-template>
<div class="input-group">
  <div class="input-group-prepend">
  <span class="input-group-text"></span>
  <span id="txt-new-message-thread" class="input-group-text"></span>
  <select class="custom-select" id="message_type">
		<option value="INFO">info</option>
		<option value="WARNING">warning</option>
		<option value="CRITICAL">critical</option>
	</select>
  </div>
  <textarea id="text-new-message" class="form-control" aria-label="With textarea" rows="1"></textarea>
  <div class="input-group-append">
	  <button id="btn-send-message" class="btn btn-outline-primary" type="button">Send</button>
  </div>
</div>
</message-template>    
<messages-navigator>
	<select id="slct-message-byorder">
		<option value="">By order</option>
	</select>
	<select id="slct-message-byuser">
		<option value="">By user</option>
	</select>
	<span>
	<input type="checkbox" data-toggle="toggle" data-size="mini" data-height="16" data-width="120" data-onstyle="default" data-on="<i class='fa fa-flag' aria-hidden='true' style='color:red;'></i> Flagged" data-off="<i class='fa fa-flag-o' aria-hidden='true'></i></i> All messages"></span>
</messages-navigator>
</messages>
<div id="loginform">
<div class="input-group">
	<div class="input-group-prepend">
	<span class="input-group-text">User name</span>
	</div>
	<input class="form-control" type="text" placeholder="Enter Username" id="username" name="username" required value="">
</div>
<div class="input-group">
	<div class="input-group-prepend">
	<span class="input-group-text">Password</span>
	</div>
	<input class="form-control" type="password" placeholder="Enter Password" id="password" required value=""></input>
	<div class="input-group-append">
	<button class="form-control btn btn-success" id="submitLogin">Login</button>
	</div>
</div>
<div class="input-group">
	<div class="input-group-prepend">
	<span class="input-group-text">Factory</span>
	</div>
	<input class="form-control" type="text" placeholder="Enter factory" id="factory" required value=""></input>
</div>
<div class="input-group">
	<div class="input-group-prepend">
	<span class="input-group-text">Timezone</span>
	</div>
	<select class="form-control" id="timezone" type="select"><option value="+0300" default="default">Moscow</option><option value="+0400">Samara</option></select>
	<div class="input-group-prepend">
	<span class="input-group-text">Language</span>
	</div>
	<select class="form-control" id="language" type="select"><option value="en" default="default">EN</option><option value="ru">RU</option></select>
</div>
<div class="container" style="background-color:#f1f1f1">
	<!--input class="form-control custom-control-input" type="checkbox" checked="checked" name="remember"> Remember me</input-->
	<span class="psw">Forgot <a href="">password?</a></span>
</div>
</div>
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
		//$('instance').outerWidth($(window).width());
		// bug Safari Bug 26559
		$('instance').outerHeight($('body').height()-$('instance').position().top);

		if (typeof(resizeOn) == 'function') resizeOn();
		$("#loadingSpinner").offset({
			top: ($('body').innerHeight() - $("#loadingSpinner").outerHeight()) / 2, 
			left: ($('body').innerWidth() - $("#loadingSpinner").outerWidth()) / 2
		});
	});
	$("#username").val(localStorage.getItem("username")?localStorage.getItem("username"):"");
	$("#factory").val(localStorage.getItem("factory")?localStorage.getItem("factory"):"");
	$("#password").val(localStorage.getItem("password")?localStorage.getItem("password"):"");
	$("#language").val(localStorage.getItem("language")?localStorage.getItem("language"):"");
	$("#timezone").val(localStorage.getItem("timezone")?localStorage.getItem("timezone"):"");
//	$("#").val(localStorage.getItem("")?localStorage.getItem(""):"");
//	$("#").val(localStorage.getItem("")?localStorage.getItem(""):"");
	$("#menu-logout").on('click', function(){
		$("messages").hide();
		$("instance").html("");
		showLoginForm();
	});
	tryLogin();
	collapseMessages();
	$("#messages-popup").on('click', function() {
		$('messages').show();
		scrollMessages();
	});
	$(window).resize();
})

$("#btn-send-message").on('click', function () {
	//debugger;
	ORMNaviMessage.send($("#text-new-message").val(), $("#message_type").val(), $("#txt-new-message-thread").text());
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
	$("#submitLogin").on ('click', function(){
		localStorage.setItem("username", $("#username").val());
		localStorage.setItem("factory", $("#factory").val());
		localStorage.setItem("password", $("#password").val());
		localStorage.setItem("language", $("#language").val());
		localStorage.setItem("timezone", $("#timezone").val());
//		localStorage.setItem("", $("#").val());
//		localStorage.setItem("", $("#").val());
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
		$('messages messages-container').animate({scrollTop: $("messages messages-container unread-separator").position().top+$("messages messages-container").scrollTop()-$("messages messages-container unread-separator").outerHeight()*2 }, 0);
	} else {
		// scroll to bottom
		$('messages messages-container').animate({scrollTop: $("messages messages-container")[0].scrollHeight}, 0);
	}
}
function filterMessages(){
	$('messages messages-container message').hide();
	$("messages messages-container message:has(message-tags:contains('"+$("#slct-message-byorder").val()+"'))",($("#slct-message-byuser").val()?" + messages messages-container message:has(message-tags:contains('@"+$("#slct-message-byuser").val()+"'))":"")).show();
	$("messages messages-container message:has(message-tags:contains('"+$("#slct-message-byorder").val()+"'))",($("#slct-message-byuser").val()?" + messages messages-container message:has(message-from:contains('"+$("#slct-message-byuser").val()+"'))":"")).show();
	//edt-search
	$("messages messages-container message:has(message-body:not(:contains('"+$("#edt-message-search").val()+"')))").hide();
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
					$("messages messages-container").prepend('<message message_id="'+ls.data[ind].id+'" read="'+(ls.data[ind].read_time || ls.data[ind].from == $("#username").val()?"1":"0")+'" in="'+(ls.data[ind].from != $("#username").val()?"1":"0")+'" flagged="'+(ls.data[ind].flagged?ls.data[ind].flagged:'0')+'"/>');
					m = new ORMNaviMessage(ls.data[ind]);
					if (!(ls.data[ind].read_time || ls.data[ind].from == $("#username").val())) {
						if ($("messages messages-container unread-separator").length) $("messages messages-container unread-separator").remove();
						$("messages messages-container").prepend('<unread-separator>Unread messages</unread-separator>');	
					}
				}
				if (unread_count)	{
					$("#messages-popup").html(unread_count+" sms");
				} else {
					$("#messages-popup").html("All read");
				}
				$("messages messages-container message message-from").prepend('<i class="fa fa-user-circle" aria-hidden="true"></i>');
				$("messages messages-container message message-time").prepend('<i class="fa fa-clock-o" aria-hidden="true"></i>');
				
				scrollMessages();
				if (NaviFactory.currentUser && NaviFactory.currentUser.subscriptions) {
					$("#slct-message-byorder").html("");
					$("#slct-message-byorder").append('<option value="">All orders</option>');
					var a = NaviFactory.currentUser.subscriptions.split(';');
					a.forEach(element => {
						$("#slct-message-byorder").append('<option value="'+element+'">'+element+'</option>');
					});
				}
				if (NaviFactory.users) {
					$("#slct-message-byuser").html("");
					$("#slct-message-byuser").append('<option value="">All users</option>');
					for (var username in NaviFactory.users) {
						if ($("#username").val() != username) {
							$("#slct-message-byuser").append('<option value="'+username+'">'+username+'</option>');
						}
					}
				}

				$('messages messages-container message[in="1"]').prepend('<button type="button" class="ml-2 mb-1 close" message="reply"><i class="fa fa-reply" aria-hidden="true"></i></button>');				
				
				$('messages messages-container message[flagged="0"][in="0"]').prepend('<button type="button" class="ml-2 mb-1 close" message="flag"><i class="fa fa-flag-o" aria-hidden="true"></i></button>');				
				$('messages messages-container message[flagged="1"]').prepend('<button type="button" class="ml-2 mb-1 close" message="flag"><i class="fa fa-flag" style="color:red" aria-hidden="true"></i></button>');				
				$('messages messages-container message[read="0"]').prepend('<button type="button" class="ml-2 mb-1 close" message="collapse"><i class="fa fa-envelope-open-o" aria-hidden="true"></i></button>');
				//$('messages messages-container message[read="1"]').prepend('<button type="button" class="ml-2 mb-1 close" message="reply"><i class="fa fa-envelope-o" aria-hidden="true"></i></button>');

				$('message button[message="reply"]').click(function(){
					$("#txt-new-message-thread").text($(this).parent()[0].ORMNaviMessage.id);
					var q = "";
					if ($(this).parent()[0].ORMNaviMessage.from.indexOf(" ")>=0) q = '"';
					$("#text-new-message").val("@"+q+$(this).parent()[0].ORMNaviMessage.from + q+" " +$("#text-new-message").val());
					$("#text-new-message").focus();					
				});

				$("#edt-message-search").change(function(){
					filterMessages();
				});
				$("#slct-message-byuser").change(function(){
					filterMessages();
				});
				$("#slct-message-byorder").change(function(){
					filterMessages();
				});
				$('message button[message="collapse"]').on ('click', function (event) {
					$(this).parent()[0].ORMNaviMessage.dismiss();
					updateMessages();
				})
				$('message button[message="flag"]').on ('click', function (event) {
					$(this).parent()[0].ORMNaviMessage.flag();
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
		top: ($('body').innerHeight() - $("#informationMessage").outerHeight()*2)
	});
	setTimeout(function() {
		$("#informationMessage").hide();
	}, 1500);
}
function tryLogin() {
	if (!$("#username").val() || !$("#factory").val()) {
		showLoginForm();
		return;
	}
	NaviFactory = new ORMNaviFactory();
}
function loadInstance() {
	if ($('instance').html()) return;
	sendDataToNavi("factory", undefined, 
	function(data, status){
		hideLoading();
		switch (status) {
			case "success":
				$("#loginform").hide();
				$("instance").html(data);
				setInterval( function () {
					NaviFactory.updateFactoryInfo();
				}, 60000);
				break;
			default:
				clearInstance();
				showLoginForm();
		}
	});
}

$("a[instance]").on ('click', function (event) {
	sendDataToNavi($(this).attr("instance"), undefined,
	function(data, status){
		$("instance").html(receiveHtmlFromNavi(data, status));
	});
})

function workcenter(id) {
	sendDataToNavi("workcenter", {workcenter:id},
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
}

function road(id) {
	sendDataToNavi("road", {road:id},
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
      <div id="dlgOrderModalBody" class="modal-body">
        ...
      </div>
      <div class="modal-footer">
		<button type="button" id="btn-subscribe" class="btn btn-success" data-dismiss="">Subscribe</button>
		<!--button type="button" class="btn btn-success" data-dismiss="">Update Est.</button>
		<button type="button" class="btn btn-success" data-dismiss="">Update Plan</button-->
    	<button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
      </div>
    </div>
  </div>
</div>
<?php include "footer.php"?>
