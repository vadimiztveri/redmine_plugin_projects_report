projectsReportsDropList = function($contaner) {
  var self = $contaner,
      $dropBottom = $contaner.find(".drop-bottom"),
      $dropbleAll = $contaner.find('#dropbleAll'),
      $dropDownArrow = $contaner.find('.drop-down-arrow'),
      $percentBottom = $contaner.find('.percent-bottom');

  $dropDownArrow.click(function(e) {
    var $target = $(e.target);
  });

  $percentBottom.click(function(e) {
    var $target = $(e.target);
  });

  $dropBottom.click(function(e) {
    var $target = $(e.target),
        projectId = $target.attr('dropforid'),
        $openedElements = $contaner.find('[dropforid=' + projectId + ']');

    if($target.hasClass('opened')){
      $openedElements.removeClass('opened');
      $openedElements.attr('title', 'Развернуть');

      self.hideRows(projectId);
    }else{
      $openedElements.addClass('opened');
      $openedElements.attr('title', 'Свернуть');
      self.showRows(projectId);
    }
  });

  $dropbleAll.click(function(e) {
    $target = $(e.target);

    if($target.hasClass('opened')){
      $target.removeClass('opened');
      self.closeAll();
      $target.text('Развернуть все');
      self.hideRows('all');
    }else{
      $target.addClass('opened');
      self.openAll();
      $target.text('Свернуть все');
      self.showRows('all');
    }
  });

  self.hideRows = function(projectId) {
    $tds = self.get_tds(projectId);
    $tds.addClass('hide');
    $tds.find('.td-content').css('display', 'none');
  };

  self.showRows = function(projectId) {
    $tds = self.get_tds(projectId);
    $tds.removeClass('hide');

    setTimeout(function() {
      $tds.find('.td-content').css('display', 'inline');
    }, 100);
  };

  self.closeAll = function() {
    $dropBottom.removeClass('opened');
    $dropBottom.attr('title', 'Развернуть');
    $dropDownArrow.removeClass('opened');
    $dropDownArrow.attr('title', 'Развернуть');
    $percentBottom.removeClass('opened');
    $percentBottom.attr('title', 'Развернуть');
  };

  self.openAll = function() {
    $dropBottom.addClass('opened');
    $dropBottom.attr('title', 'Свернуть');
    $dropDownArrow.addClass('opened');
    $dropDownArrow.attr('title', 'Свернуть');
    $percentBottom.addClass('opened');
    $percentBottom.attr('title', 'Свернуть');
  };

  self.get_tds = function(projectId) {
    if(projectId == 'all') {
      return $contaner.find('.dropble');
    }else{
      return $contaner.find('[dataprojectid=' + projectId + ']');
    }
  };
};

$(document).ready(function() {
  var $byLeaders = $('#by_leaders'),
      $byPercentDesc = $('#by_percent_desc'),
      $byPercentAsc = $('#by_percent_asc');

  projectsReportsDropList($byLeaders);
  projectsReportsDropList($byPercentDesc);
  projectsReportsDropList($byPercentAsc);
});
