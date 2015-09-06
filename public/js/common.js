
var delete_confirm = function(target, did, dform){
  if (confirm("Are you sure")) {
    var id = target.parent("td").children("input").val();
    did.val(id);
    dform.submit();
  }
};

$(function(){
  // Delete category
  $(".del_category_btn").on("click", function(){
    delete_confirm($(this), $("#del_category_id"), $("#del_category_form"));
  });

  // Delete user
  $(".del_user_btn").on("click", function(){
    delete_confirm($(this), $("#del_user_id"), $("#del_user_form"));
  });

  // Delete file
  $(".del_file_btn").on("click", function(){
    delete_confirm($(this), $("#del_file_id"), $("#del_file_form"));
  });
});

function toggle_disable(box_name){
  $(document).ready(function(){
    $box_name = $(box_name);
    $button_name = $(box_name + "-readonly-button");
    if ($box_name.attr("readonly")) {
      $($box_name).removeAttr("readonly");
      $($button_name).html("Back");
    } else {
      $box_name.attr("readonly", "false");
      $($button_name).html("Edit");
    }
  });
}
