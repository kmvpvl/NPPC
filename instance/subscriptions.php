<?php
include "checkORMNavi.php";
$factory->hasRoleOrDie(["USER_MANAGEMENT"]);
?>
<script>
//debugger;
$(".nav-link.active").removeClass("active");
$(".nav-item.active").removeClass("active");
$("#menuSubscriptions").addClass("active");
$(".navbar-brand").text(NaviFactory.name+": My subscriptions");
NaviFactory.on('change', function(){
    redraw();
})

function redraw() {
    $("#text-my-subscriptions").val(NaviFactory.currentUser.subscriptions);
}
redraw();
$('#btn-save-my-subscriptions').click(function(){
    sendDataToNavi("apiSubscribe", {tag: $('#text-my-subscriptions').val()}, function(data, status){
        var ls = recieveDataFromNavi(data, status);
        if (ls && ls.result=='OK') {
            NaviFactory.currentUser = ls.data;
            showInformation("Your subscriptions saved successfully...");
            redraw();
        }
    });
});
</script>
<div class="input-group">
  <div class="input-group-prepend">
  <span class="input-group-text" id="btn-new-user">Subscriptions</span>
  </div>
  <textarea id="text-my-subscriptions" class="form-control" aria-label="With textarea" rows="5"></textarea>
  <div class="input-group-append">
	  <button id="btn-save-my-subscriptions" class="btn btn-outline-secondary" type="button">Save</button>
  </div>
</div>
