addBorderForSticky = function() {
  var self = this,
      $sticky = $('.left.first.first-row'),
      stickyVisibale = false,
      $ths = $('th.first-row');

  $(window).scroll(function() {
    var stickyPosition = $sticky.position().top;

    if(self.isSticky(stickyPosition) && !self.stickyVisibale) {
      self.showBorder();
      self.stickyVisibale = true;
    }

    if(!self.isSticky(stickyPosition) && self.stickyVisibale) {
      self.hideBorder();
      self.stickyVisibale = false;
    }
  });

  isSticky = function(stickyPosition){
    return stickyPosition > 66;
  };

  showBorder = function () {
    $ths.addClass('show');
  };

  hideBorder = function () {
    $ths.removeClass('show');
  };
};

$(document).ready(addBorderForSticky());
