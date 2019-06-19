projectsReports = function() {
  var $filterHeaders = $(".filterHeader"),
      $cross = $(".cross"),
      $checkBoxAll = $(".checkBoxAll");

  $filterHeaders.click(function(event) {
    changeClass(event);
  });

  $cross.click(function(event) {
    changeClass(event);
  });

  $checkBoxAll.change(function(e) {
    var $target = $(e.target),
        checked = $target.is(":checked"),
        $all_boxes = $target.parents('.list').find('.list_item');

    $all_boxes.prop('checked', checked);
  });

  changeClass = function(event) {
    $target = $(event.target);
    $filter = $target.parents('.projects_reports_filter');

    if ($filter.hasClass('opened')) {
      $filter.removeClass('opened');
      $filter.addClass('closed');
    } else {
      $filter.removeClass('closed');
      $filter.addClass('opened');
    }
  };
};

$(document).ready(projectsReports());
