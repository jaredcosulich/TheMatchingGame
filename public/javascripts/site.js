function showFailure(failureMessage) {
  $('.anonymous_error').html(failureMessage).fadeIn();
}

function thankYou() {
  $('.anonymous_warning_text').slideUp(
    1000,
    function() {
      $('.anonymous_warning_thankyou').slideDown(
        800,
        function () {
          $('.anonymous_warning').delay(2000).slideUp(600);
        }
      )
    }
  )
}

function submitEmail(){
  trackEvent("email_registration", "register", window.TMG_DATA.PLAYER_ID);
  var name = $('#name').val()
  var firstName = name.split(/\s/)[0];
  var lastName = name.replace(firstName + " ", "");
  $.ajax({
    type: 'POST',
    url: "/account",
    dataType: "json",
    data: {player: {user_attributes: {email: $('#email').val()}, profile_attributes: {first_name: firstName, last_name: lastName}}},
    success: function(response) {
      if (response.errorMessage) {
        showFailure(response.errorMessage);
      } else {
        thankYou();
        location.reload();
      }
    }
  })
}

function trackEvent(category, action, opt_label, opt_value){
  pageTracker._trackEvent(category, action, opt_label, opt_value);
}
