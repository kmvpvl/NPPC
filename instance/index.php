<?php include "header.php"?>
<script src="naviNPPC.js"></script>
<?php include "menu.php"?>
<instance>
</instance>
<messages>
<messages-shortcut>
<span class="badge badge-primary">New</span>
</messages-shortcut>    
<messages-toolbar>
<strong class="mr-auto>">Messages</strong>
<input type="checkbox" checked="1">success</input>
<input type="checkbox" checked="1">warnings</input>
<input id="btn-new-message" type="button" value="[new]"></input>
<button type="button" class="ml-2 mb-1 close" messages="collapse">&times;</button>
<message-template>
<div class="input-group mb-0">
    <div class="input-group-prepend">
        <span class="input-group-text">@</span>
    </div>
    <input id="message_order" type="text" class="form-control" placeholder="Order" aria-label="Order">
    <div class="input-group-text">
        <input type="checkbox" aria-label="Checkbox for following text input">
    </div>
    <input id="message_to" type="text" class="form-control" placeholder="Username" aria-label="Username">
    <select class="custom-select" id="message_type">
        <option value="primary">info</option>
        <option value="warning">warning</option>
        <option value="danger">danger</option>
    </select>
    <div class="input-group-append">
        <button id="btn-send-message" class="btn btn-outline-secondary" type="button">Send</button>
    </div>
</div>
<div class="input-group">
  <div class="input-group-prepend">
    <span class="input-group-text">Text</span>
  </div>
  <textarea id="message_text" class="form-control" aria-label="With textarea"></textarea>
</div>
</message-template>    
</messages-toolbar>
<messages-container>
</messages-container>
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
function collapseMessages() {
    $('messages messages-container').hide();
    $('messages messages-toolbar').hide();
    $('message-template').hide();
    $('messages messages-shortcut').show();
    $('messages').removeClass('expanded');
    $('messages').addClass('collapsed');
	$('messages').css('top', -$('messages').outerWidth() + "px");
}
$(document).ready (function (){
	collapseMessages();
	$(window).resize();
	tryLogin();
})

$("#btn-new-message").on('click', function (){
    $('message-template').show();
})
$('#message_order').on ('change', function () {
    
})
$('#message_to').on ('input', function () {
	var p = $.post("apiGetUserByLetters.php",
	{
		username: $("#username").val(),
		factory:  $("#factory").val(),
		password: $("#password").val(),
		language: $("#language").val(),
		timezone: $("#timezone").val(),
		letters: $('#message_to').val()
	},
	function(data, status){
		hideLoading();
		//debugger;
		switch (status) {
			case "success":
			    var users = jQuery.parseJSON(data);
			    if (users.length == 1) {
			        $('#message_to').val(users[0]);
			    }
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
})
$("#btn-send-message").on('click', function () {
	showLoading();
	//debugger;
	var p = $.post("apiSendMessage.php",
	{
		username: $("#username").val(),
		factory:  $("#factory").val(),
		password: $("#password").val(),
		language: $("#language").val(),
		timezone: $("#timezone").val(),
		message_type: $('#message_type').val(),
		message_text: $('#message_text').val(),
		message_order: (('' == $('#message_order').val())?undefined : $('#message_order').val()),
		message_to: (('' == $('#message_to').val())?undefined : $('#message_to').val()),
		message_reply: $('#message_reply').val()
	},
	function(data, status){
		hideLoading();
		//debugger;
		switch (status) {
			case "success":
                $('message-template').hide();
                updateMessages();
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
})

function makeMessageRead(_message_id) {
	showLoading();
	var p = $.post("apiMakeMessageRead.php",
	{
		username: $("#username").val(),
		factory:  $("#factory").val(),
		password: $("#password").val(),
		language: $("#language").val(),
		timezone: $("#timezone").val(),
		message_id: _message_id
	},
	function(data, status){
		hideLoading();
		//debugger;
		switch (status) {
			case "success":
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


function updateMessages() {
    $("messages messages-container").html = '';
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
				$("messages messages-container").html(data);
                $('messages messages-container message').prepend('<button type="button" class="ml-2 mb-1 close" message="collapse">&times;</button>');
                $('message button[message="collapse"]').on ('click', function (event) {
                    message_id = event.currentTarget.parentElement.attributes['message_id'].nodeValue;
                    makeMessageRead(message_id);
                    $('message[message_id="' + message_id + '"]').hide();
                })
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
$('messages').on ('click', function (){
    if ($('messages').hasClass('expanded')) return;
    $('messages').removeClass('collapsed');
    $('messages').addClass('expanded');
    $('messages messages-container').show();
    $('messages messages-toolbar').show();
    $('messages messages-shortcut').hide();
	$('messages').css('top', -$('instance').innerHeight()*0.67 + "px");
	$('messages').css('height', $('instance').innerHeight()*0.67 + "px");
    $('messages messages-toolbar button[messages="collapse"]').on('click', function (event) {
        collapseMessages();
        event.stopPropagation();
    })
    updateMessages();
})

$(window).resize(function() {
	$('instance').css('height', $(window).height()-$('instance').offset().top + "px");
	$("#loadingSpinner").offset({
		top: ($('instance').outerHeight() - $("#loadingSpinner").outerHeight()) / 2, 
		left: ($('instance').outerWidth() - $("#loadingSpinner").outerWidth()) / 2
	});
})


function clearInstance() {
	$("instance").html = "";
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
<div class="modal fade" id="dlgModal" tabindex="-1" role="dialog" aria-labelledby="dlgModalLongTitle" aria-hidden="true">
  <div class="modal-dialog" role="document">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="dlgModalLongTitle">Modal title</h5>
        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
          <span aria-hidden="true">&times;</span>
        </button>
      </div>
      <div class="modal-body">
        ...
      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-dismiss="modal">Cancel</button>
        <button type="button" dlg-button="btn-dlgModal-ok" class="btn btn-primary"></button>
      </div>
    </div>
  </div>
</div>

<?php include "footer.php"?>
