$(function(){
  $(".processed_group_loaded").error(function() {
    var self = $(this);
    setTimeout(function() {
      self.attr("src", function() {
        return self.attr('src') + '1';
      });
    }, 2500);
  }).load(function() {
    $(this).show().unbind('error').unbind('load').removeClass('processed_group_loaded').prev('.processed_group_loading').hide();
  }).attr("src", function() {
    return $(this).attr('data-src') +  new Date().getTime();
  });


});

$(function(){
  $(".photo_set .thumbnails .thumbnail").live('click', function(){
    var photo_set = $(this).closest('.photo_set');
    photo_set.find('.large_photo').hide();
    photo_set.find('#' + $(this).attr('id').replace("_thumbnail", "")).show();
  });
});
