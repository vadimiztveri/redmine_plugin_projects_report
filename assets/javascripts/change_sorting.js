changeSorting = function() {
  var self = this,
      $projectsReportsSorting = $(".projects_reports_sorting"),
      $selected = $('.selected'),
      $datatypeByProgress = $('[datatype=by_progress]'),

      $byLeaders = $('#by_leaders'),
      $byPercentAsc = $('#by_percent_asc'),
      $byPercentDesc = $('#by_percent_desc');

  $projectsReportsSorting.click(function(event) {
    var $target = $(event.target),
        type = $target.attr('datatype');

    $selected.addClass('hide');

    if (type == 'by_leaders') {
      $byLeaders.removeClass('hide');
    } else {
      if ($target.hasClass('asc')) {
        $datatypeByProgress.removeClass('asc');
        $byPercentAsc.removeClass('hide');
      } else {
        $datatypeByProgress.addClass('asc');
        $byPercentDesc.removeClass('hide');
      }
    }
  });
};

$(document).ready(changeSorting());
