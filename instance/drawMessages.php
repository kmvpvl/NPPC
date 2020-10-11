<?php
include "checkUser.php";
try {
	$r = $navi->getMessages();
} catch (Exception $e) {
	http_response_code(400);
	die ($e->getMessage());
}
?>
<script>
function resizeMessageCenter() {
    $("#content-div").css('height', $(window).height() - $("#content-div").offset().top - 15 + "px");
}

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
<div id="content-div" class="ml-1 mr-1">
	<div class="row mt-0">
<?php
$i = 0;
foreach ($r as $msg) {
?>
		<div class="col-sm-4">
<div class="toast fade show" data-autohide="false" id="toast_<?= $msg["id"] ?>">
<div class="toast-header">
<strong class="mr-auto text-<?= $msg["message_type"] ?>"><?= $msg["user_name"] ?></strong>
<small class="text-muted"><?= $msg["message_time"] ?></small>
<button type="button" class="ml-2 mb-1 close" data-dismiss="toast">&times;</button>
</div>
<div class="toast-body">
<?= $msg["user_name"] ?>: <?= $msg["body"] ?>
</div>
</div>
		</div>
<?php
    $i++;
    if ($i % 3 == 0) {
?>
	</div>
	<div class="row mt-0">
<?php
    }
}
?>
	</div>
</div>