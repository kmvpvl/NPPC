<?php
include "checkORMNavi.php";
$factory->hasRoleOrDie(["USER_MANAGEMENT"]);
?>
<script>
//debugger;
$(".nav-link.active").removeClass("active");
$(".nav-item.active").removeClass("active");
$("#menuUsers").addClass("active");
$(".navbar-brand").text(NaviFactory.name+": Users");
NaviFactory.on('change', function(){
    redraw();
})
function drawRoles() {
    var s = '';
    for (let [irole, orole] of Object.entries(NaviFactory.roles)){
        s += '<div>';
        s += '<input type="checkbox" role="'+orole.name+'">'+orole.description+'</input>';
        if (orole.context) {
            for (let [icnt, ocnt] of Object.entries(orole.context)) {
                s += '<div class="role-context"><input type="checkbox" role="'+irole+'%'+icnt+'">'+ocnt+'</input></div>';
            }
        }
        s += '</div>';
    }
    $("#roles-tab").html(s);
}
function drawSubscriptions(){

}

function redraw() {
    var selected_user = null;
    if ($('factory-user.selected').length == 1) selected_user = $('factory-user.selected').attr('user_id');
    s = '';
    for (let [iuser, ouser] of Object.entries(NaviFactory.users)) {
        s += '<factory-user user_name="'+ouser.name+'" user_id="'+ouser.id+'"><user-controls></user-controls><user-name>'+iuser+'</user-name><user-roles>'+ouser.roles+'</user-roles><user-subscriptions>'+ouser.subscriptions+'</user-subscriptions></factory-user>';
    }
    $("#usersList").html(s);
    $('factory-user').click(function(){
        $('factory-user').removeClass('selected');
        $('factory-user > user-controls').html('');
        $(this).addClass('selected');
        $(this).find('user-controls').html(' <i class="fa fa-pencil" aria-hidden="true"></i> <i class="fa fa-ban" aria-hidden="true"></i> ');
        $(this).find('user-controls > i').click(function(){
            if ($('factory-user.selected').length != 1) return;
            drawRoles();
            var user_name = $('factory-user.selected').attr('user_name');
            var str_user_roles = NaviFactory.users[user_name].roles;
            var arr_user_roles = str_user_roles.split(';');
            for (var r in arr_user_roles) {
                $('input[type="checkbox"][role="'+arr_user_roles[r]+'"]').prop('checked', 1);
            }
            $("#txt-user-name").val(user_name);
            $("#txt-user-name").prop("readonly", true);
            $('#text-user-subscriptions').val(NaviFactory.users[user_name].subscriptions);
            $('#tabs-user a:first').tab('show');
            $('#dlgUserModal').modal('show');
        });
  });
  if (selected_user) $('factory-user[user_id="'+selected_user+'"]').click();
}
redraw();
$('#btn-save-user').click(function(){
    //debugger;
    var s = '';
    var user_id = undefined;
    var user_name = '';
    $('input:checked[type="checkbox"][role]').each(function(){
        s += (s?';':'') + $(this).attr('role');
    });
    if ($('factory-user.selected').length == 1) {
        user_name = $('factory-user.selected').attr('user_name');
        user_id = $('factory-user.selected').attr('user_id');
    } else {
        user_name = $("#txt-user-name").val();
    }
    sendDataToNavi("apiSaveUser", {id: user_id, name: user_name, roles: s, ban: null, subscriptions: $('#text-user-subscriptions').val()}, function(data, status){
        var ls = recieveDataFromNavi(data, status);
        if (ls && ls.result=='OK') {
          showInformation("User saved successfully...");
          NaviFactory.users[user_name] = ls.data;
          redraw();
        }
    });
});
$('#btn-new-user').click(function(){
    $('factory-user').removeClass('selected');
    $('factory-user > user-controls').html('');
    $("#txt-user-name").val('');
    $("#txt-user-name").prop("readonly", false)
    $('#text-user-subscriptions').val('');
    drawRoles();
    $('#tabs-user a:first').tab('show');
    $('#dlgUserModal').modal('show');
});
function searchUsers(){
  if ($('#txt-serach-user').val()==''){
    $('factory-user').show();
  } else {
    $('factory-user').hide();
    $('factory-user:contains('+$('#txt-serach-user').val()+')').show();
  }
}
$('#txt-search-user').change(function(){
  searchUsers();
});
$('#btn-search-user').click(function(){
  searchUsers();
});
</script>
<users>
<div class="input-group">
  <div class="input-group-prepend">
  <span class="input-group-text" id="btn-new-user"><i class="fa fa-plus-square" aria-hidden="true"></i></span>
  </div>
  <input id="txt-search-user" type="text" class="form-control" placeholder="Search user..."></input>
  <div class="input-group-append">
	  <button id="btn-search-user" class="btn btn-outline-secondary" type="button">Search</button>
  </div>
</div>

<span id="usersList"></span>
</users>
<div class="modal fade" id="dlgUserModal" tabindex="-1" role="dialog" aria-labelledby="dlgUserModalLongTitle" aria-hidden="true">
  <div class="modal-dialog" role="document">
    <div class="modal-content">
      <div class="modal-header">
      <h3>User&nbsp;</h3>
      <input type="text" class="form-control" placeholder="Enter user name..." id="txt-user-name"></input>
        <button type="button" class="close" data-dismiss="modal" aria-label="Close">
          <span aria-hidden="true">&times;</span>
        </button>
      </div>
      <div class="modal-body">
        <ul id="tabs-user" class="nav nav-tabs">
        <li class="nav-item">
          <a class="nav-link active" data-toggle="tab" href="#roles-tab">Roles</a>
        </li>
        <li class="nav-item">
          <a class="nav-link" data-toggle="tab" href="#subscriptions-tab">Subscriptions</a>
        </li>
        </ul>
      </div>
      <div class="tab-content">
        <div id="roles-tab" class="container tab-pane active">
        </div>
        <div id="subscriptions-tab" class="container tab-pane fade">
          <textarea id="text-user-subscriptions" class="form-control" aria-label="With textarea" rows="5"></textarea>
        </div>
      </div>
      <div class="modal-footer">
		<button type="button" id="btn-save-user" class="btn btn-success" data-dismiss="modal">Apply</button>
    	<button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
      </div>
    </div>
  </div>
</div>
