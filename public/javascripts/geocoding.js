$(function() {
  google.load("maps", "2", {"callback": geocode});

  function geocode() {
    var geocoder = new GClientGeocoder();

    var locationNameField = $("#player_profile_attributes_location_name");
    var locationLatField = $("#player_profile_attributes_location_lat");
    var locationLngField = $("#player_profile_attributes_location_lng");
    var locationForm = locationNameField.closest('form');
    var locationName = locationNameField.val();
    var lookingUpLocation = false;

    var geocodeLocation = function(submit) {
      if (lookingUpLocation) return false;
      if (locationNameField.val() == locationName) return true;
      locationName = locationNameField.val();
      lookingUpLocation = true;
      geocoder.getLatLng(
        locationName,
        function(point) {
          if (!point) point = {x: '', y: ''};
          lookingUpLocation = false;
          locationLatField.val(point.y);
          locationLngField.val(point.x);
          if (submit) geocodeLocation(submit);
        }
      );

      return false;
    };

    locationNameField.change(geocodeLocation);
    locationForm.submit(
      function() {
        geocodeLocation(true)
      }
    );

    var location = google.loader.ClientLocation;
    if ($("#player_profile_attributes_location_name").val().length == 0 && location) {
      locationNameField.val(location.address.city + ", " + location.address.region + ", " + location.address.country);
      locationLatField.val(location.latitude);
      locationLngField.val(location.longitude);
    }
  }
});

$(function(){
  function setProfilePreview() {
    var preferredProfile = $("input[name='preferred_profile']:checked").val();
    if (preferredProfile == 'facebook') {
      $('#profile_preview_text').html($('#facebook_name_age_and_place').html());
    } else {
      var text = $('#player_profile_attributes_first_name').val();
      if (text.length == 0) {
        text = "Please enter your first name to see the preview."
      } else {
        if ($("#player_profile_attributes_last_name").val().length > 0) {
          text += " " + $('#player_profile_attributes_last_name').val()[0] + ".";
        }
        var birthdate = new Date($('#player_profile_attributes_birthdate_2i').val() + "/" + $('#player_profile_attributes_birthdate_3i').val() + "/" + $('#player_profile_attributes_birthdate_1i').val());
        var years = parseInt((new Date() - birthdate) / (365 * 24 * 60 * 60 * 1000));
        if (!isNaN(years)) {          
          text += " (";
          text += years;
          text += " yrs)";
        }
        if ($("#player_profile_attributes_location_name").val().length > 0) {
          text += " from " + $('#player_profile_attributes_location_name').val();
        }
      }
      $('#profile_preview_text').html(text);
    }
  }

  setProfilePreview();

  $('.profile_input').keyup(setProfilePreview);
  $('.profile_input').change(setProfilePreview);

  $("input[name='preferred_profile']").click(setProfilePreview);
});
