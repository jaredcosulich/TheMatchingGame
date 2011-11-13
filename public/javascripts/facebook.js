function withFB(fn, delay) {
  if (!delay) delay = 1;
  if (window.FB && FB.getSession()) {
    fn();
  }
  else {
    setTimeout(function() {
      withFB(fn, delay * 1.2)
    }, delay);
  }
}

function setFacebook(session, email, onSuccess) {
  if (!session) return;
  setFBStatus(session, email);
  saveFacebookEmailAndProfile(session, onSuccess);
}

function loadFbStatus(sendProfile) {
  var session = FB.getSession();
  if (session) {
    query("select uid, email from permissions where uid = " + session.uid, function(permissions) {
      if ($.isArray(permissions)) permissions = permissions[0];
      setFBStatus(session, permissions.email);
      if (sendProfile) saveFacebookEmailAndProfile(session);
    });
  }
}

function setFBStatus(session, email) {
  var body = $(document.body);
  if (session) body.removeClass('no_facebook').addClass('with_facebook');
  if (email) body.removeClass("no_facebook_email").addClass("with_facebook_email")
}

function saveFacebookEmailAndProfile(session, onSuccess) {
  query("/me", function(profile){
    saveProfile(profile, onSuccess);
  });
  query("select uid, sex, current_location from user where uid = " + session.uid, saveProfile);
}

function saveProfile(profile, onSuccess) {
  if ($.isArray(profile)) profile = profile[0];
  $.post("/account/profile/facebook", {fb_info: profile}, onSuccess);
}


function loadFacebookPhotos() {
  var content = $("#facebook_photos");

  if (content.html().length > 0) return;

  function addPhotos(photos) {
    $.each(photos, function() {
      if (this.src != undefined || this.pic != undefined) {
        content.append(
          $("<div>").addClass('facebook_photo').append(
            $("<img/>").attr('src', this.src || this.pic)
          ).append(
            $("<input type='radio' name='facebook_photo'/>").attr('value', this.src_big || this.pic_big)
          )
        );
      }
    });
  }

  query(
    "select pic, pic_big from user where uid =" + FB.getSession().uid, function(response){
      addPhotos(response)
      query("select src, src_big from photo where pid in (SELECT pid FROM photo_tag WHERE subject=" + FB.getSession().uid + "ORDER BY created DESC LIMIT 1,15)",
      function(response) {
        addPhotos(response);
        query(
          "select src, src_big from photo where aid in (SELECT aid FROM album where owner=" + FB.getSession().uid + "ORDER BY created DESC LIMIT 1,15)",
          function(response) {
            addPhotos(response);
            if ($(".facebook_photo", content).length == 0) content.html("We were unable to find any photos with you tagged in them on Facebook.");
          }
        )
      }
  );

  });
}

function brag() {
  trackEvent("facebook_brag", "open", window.TMG_DATA.PLAYER_ID);
  FB.ui({
    method: 'stream.publish',
    message: 'just played a perfect round of matching on The Matching Game!',
    attachment: {
      name: 'Think you can do better?',
      caption: 'Play the Matching Game',
      description: (
          'Bringing A Little Serendipity and Mystery to Online Dating'
          ),
      href: window.TMG_DATA.FB_APP_URL + "?r=fbbl",
      media: [
        { 'type': 'image', 'src': 'http://www.thematchinggame.com/images/thumbnail.jpg', 'href': 'http://www.thematchinggame.com'}
      ]
    },
    action_links: [
      { text: 'Play The Matching Game', href: window.TMG_DATA.FB_APP_URL + "?r=fbba"}
    ]
  },

  function(response){
    if (response && response.post_id) {
      trackEvent("facebook_brag", "success", window.TMG_DATA.PLAYER_ID);
    } else {
      trackEvent("facebook_brag", "cancel", window.TMG_DATA.PLAYER_ID);
    }
  });
}

function facebook_share() {
  trackEvent("facebook_share", "open", window.TMG_DATA.PLAYER_ID);
  FB.ui({
    method: 'stream.publish',
    message: "I just discovered this new site, The Matching Game. It's the most amazing thing I've ever seen in my life. If you don't check it out you may regret it for the rest of your life. I'm serious. Drop everything now and go check it out.",
    attachment: {
      name: 'Play The Matching Game',
      caption: 'The Matching Game',
      description: (
          'Bringing A Little Serendipity and Mystery to Online Dating'
          ),
      href: window.TMG_DATA.FB_APP_URL + "?r=fbs",
      media: [
        { 'type': 'image', 'src': 'http://www.thematchinggame.com/images/thumbnail.jpg', 'href': 'http://www.thematchinggame.com'}
      ]
    },
    action_links: [
      { text: 'Play The Matching Game', href: window.TMG_DATA.FB_APP_URL + "?r=fbba"}
    ]
  },

  function(response){
    if (response && response.post_id) {
      trackEvent("facebook_share", "success", window.TMG_DATA.PLAYER_ID);
    } else {
      trackEvent("facebook_share", "cancel", window.TMG_DATA.PLAYER_ID);
    }
  });
}

function facebook_couples(score, image1, image2) {
  var link = location.href  
  trackEvent("facebook_couples", "open", window.TMG_DATA.PLAYER_ID);
  FB.ui({
    method: 'stream.publish',
    message: "We just scored a " + score + "% in the Perfect Pair Challenge!\n\nThink you can do better?\n\n" + link + "?r=fbc&cf=1",
    attachment: {
      name: 'View our results from the Perfect Pair Challenge >',
      caption: 'The Perfect Pair Challenge on The Matching Game',
      description: (
        'A little fun competition between couples brought to you by The Matching Game'
      ),
      href: link + "?r=fbc&cf=1",
      media: [
        { 'type': 'image', 'src': image2, 'href': link + "?r=fbc&cf=1"},
        { 'type': 'image', 'src': image1, 'href': link + "?r=fbc&cf=1"}
      ]
    },
    action_links: [
      { text: 'Play The Matching Game', href: window.TMG_DATA.FB_APP_URL + "?r=fbba"}
    ]
  },

  function(response){
    if (response && response.post_id) {
      trackEvent("facebook_couples", "success", window.TMG_DATA.PLAYER_ID);
    } else {
      trackEvent("facebook_couples", "cancel", window.TMG_DATA.PLAYER_ID);
    }
  });
}

function query(queryString, onSuccess) {
  var queryArg = queryString.indexOf("/") == 0 ? queryString : {method: 'fql.query', query: queryString}
  var callback = onSuccess ? function(response){
    if (response.error_code) {
      log(response);
    } else {
      onSuccess(response);
    }
  } : log;
  FB.api(queryArg, callback);

}

$(function(){
  $('#log_out').click(function(){FB.logout()});
});


$(function() {
  function hasEmailPermission(response) {
    return response && response.perms && response.perms.indexOf('email') > -1;
  }

  function reload() {
    location.reload();
  }

  $(".fb_connect").click(function() {
    FB.login(function(response) {
      if (response.session) {
        saveFacebookEmailAndProfile(response.session, function() {
          location.href = '/account';
        })
      }
    }, {perms:'email'})
  });

  $(".email_connect").click(function() {
    FB.login(function(response) {
      setFacebook(response.session, hasEmailPermission(response), thankYou)
    }, {perms:'email'})
  });

  $(".fb_profile_info").click(function() {
    FB.login(function(response) {
      setFacebook(response.session, hasEmailPermission(response), reload);
    }, {perms:'email'})
  });

  $(".photo_connect").click(function() {
    FB.login(function(response) {
      setFacebook(response.session, hasEmailPermission(response), loadFacebookPhotos);
    }, {perms: 'email, user_photos, user_photo_video_tags'})
  });
});
