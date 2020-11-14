<?php
include "checkUser.php";
//var_dump($_POST);
try {
	$r = $navi->getMessages();
} catch (Exception $e) {
	http_response_code(400);
	die ($e->getMessage());
}
?>
<script>
function resizeMessageCenter() {
    //$("#content-div").css('height', $(window).height() - $("#content-div").offset().top - 15 + "px");
}

$(".toast").toast();
$(".toast").on('hidden.bs.toast', function (event) {
	showLoading();
	var p = $.post("apiMakeMessageRead.php",
	{
		username: $("#username").val(),
		factory:  $("#factory").val(),
		password: $("#password").val(),
		language: $("#language").val(),
		timezone: $("#timezone").val(),
		message_id: event.target.attributes["message_id"].value
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
});

</script>
<ul class="nav nav-tabs">
  <li class="nav-item">
    <a class="nav-link active primary" href="#">All</a>
  </li>
  <li class="nav-item">
    <a class="nav-link" href="#">Warnings</a>
  </li>
  <li class="nav-item">
    <a class="nav-link" href="#">Info</a>
  </li>
  <li class="nav-item">
    <a class="nav-link" href="#">Search</a>
  </li>
  <li class="nav-item">
    <a class="nav-link" href="#">New</a>
  </li>
</ul>
<div id="content-div" class="content-div ml-1 mr-1">
<?php
$i = 0;
foreach ($r as $msg) {
    $pos = "";
    switch ($i % 3) {
        case 0:
            $pos = "b-toaster-top-left";
            break;
        case 1:
            $pos = "b-toaster-top-center";
            break;
        case 2:
            $pos = "b-toaster-top-right";
            break;
    }
?>
<div class="toast fade show" role="alert" aria-live="assertive" aria-atomic="true" data-autohide="false" message_id="<?= $msg["id"] ?>">
<div class="toast-header">
<strong class="mr-auto text-<?= $msg["message_type"] ?>"><?= $msg["user_name"] ?></strong>
<small class="text-muted"><?= $msg["message_time"] ?></small>
<button type="button" class="ml-2 mb-1 close" data-dismiss="toast">&times;</button>
</div>
<div class="toast-body">
<?= $msg["user_name"] ?>: <?= $msg["body"] ?>
</div>
</div>
<?php
    $i++;
}
?>
</div>
