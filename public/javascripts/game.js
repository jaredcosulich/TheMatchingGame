function startGame(id, gameData, endlessGame, trackingFunction, animationTime, challenge, matchMe, multiplier) {
  var self = this;
  var progressSoFar = $("#progress_so_far");
  var progressCount = $("#progress_count");
  var answeredSoFarCount = 0;

  this.doDelayed = function(fn, delay) {
    setTimeout(fn, delay);
  };

  this.setLocation = function(href) {
    window.location.href = href;
  };

  this.answerQueue = [];
  this.postAnswer = function (identifyingInfo, response, successFunction) {
    if (!self.gameId && identifyingInfo.comboId) {
      if (this.answerQueue.length == 0) {
        var data = {};
        if (window.google && google.loader && google.loader.ClientLocation) {
          data.location = google.loader.ClientLocation;
        }

        $.ajax({
          type: 'POST',
          url: "/games",
          dataType: "json",
          data: data,
          success: function(response) {
            self.setGameId(response.id);
          }
        })
      }
      this.answerQueue.push(arguments);
    } else if (identifyingInfo.matchMeId) {
      $.ajax({
        type: 'POST',
        url: "/match_me/" + identifyingInfo.matchMeId + "/games/" + self.gameId + "/answers",
        data: {
          answer: {
            other_photo_id: identifyingInfo.otherPhotoId,
            answer: response,
            game: "match_me"
          }
        },
        success: successFunction
      });
    } else {
      $.ajax({
        type: 'POST',
        url: "/games/" + self.gameId + "/answers",
        data: {
          answer: {
            combo_id: identifyingInfo.comboId,
            answer: response
          }
        },
        success: successFunction
      });
    }
  };

  this.getMoreCombos = function() {
    var comboIds = []
    for (var i=gameData.length - 1; i>gameData.length - 50 && i>=0; --i) {
      comboIds.push(gameData[i].id)
    }

    $.ajax({
      type: 'POST',
      url: "/games/" + self.gameId + "/more_combos",
      dataType: "json",
      data: {excluded_ids:comboIds},
      success: function(response) {
        $.each(response, addCombo);
        gameData = gameData.concat(response);
      }
    })
  };

  this.setGameId = function(gameId) {
    self.gameId = gameId;
    $.each(this.answerQueue, function() {
      self.postAnswer(this[0], this[1], this[2]);
    });
    this.answerQueue = [];
  };

  self.gameId = id;

  if (animationTime == undefined) animationTime = 1000;
  var container = $("#container");
  var gameHeight = $(document).height() - 400;
  var minHeight = multiplier ? 546 : 516;
  if (gameHeight < minHeight) gameHeight = minHeight;
  container.height(gameHeight);

  var goToAnswers = function(delay) {
    if ($('#completed').hasClass('help_request')) return;
    var destination = $('#completed').attr('x-data-post-game-location');
    changeLocation(destination || "/games", delay);
  };

  var changeLocation = function(location, delay){
    self.doDelayed(function() { self.setLocation(location) }, delay);
  };

  var positionPhoto = function(image) {
    var photo = image.closest(".photo");
    photo.removeClass("not_loaded_photo");
    var photoContainerHeight = photo.closest('.photo_container').height();
    if (!photoContainerHeight) {
      setTimeout(function() {
        positionPhoto(photo);
      }, 50);
      return;
    }
    photo.css('margin-top', (((photoContainerHeight - photo.height()) / 2) - 15) + 'px')
         .css('width', image.width());
  };

  $('.inline_forms form').submit(function() {
    $('#completed').removeClass('help_request');
    $.ajax({
      type: 'PUT',
      dataType: "json",
      url: "/player",
      data: $(this).serialize(),
      success: function() {
        goToAnswers(0);
      }
    });
    return false;
  });

  var photosLoaded = {};
  function photo(src, partnerSrc, interests, left){
    return $("<div/>").addClass('photo_container')
                      .append(
                        $("<div/>").addClass("photo")
                                   .addClass("not_loaded_photo")
                                   .addClass(left ? "left_photo" : "right_photo")
                                   .append(
                                     $("<img/>").load(function() {
                                       photosLoaded[src] = true;
                                       if (photosLoaded[partnerSrc]) self.doDelayed(function() { window.scrollTo(0,1); }, 100);
                                       positionPhoto($(this));
                                     }).attr("src", src)
                                   ).append(
                                     $("<div/>").addClass("interests")
                                                .addClass("explanation")
                                                .addClass("hidden_interests")
                                                .append(
                                                  $("<div/>")
                                                    .html("Interests: ")
                                                    .append($("<span/>").html(interests.length > 0 ? interests : "none yet"))
                                                )
                                   )
                      );
  }

  function button(combo, verified, yesAnswer, successFunction, buttonMultiplier) {
    if (!buttonMultiplier) buttonMultiplier = "";
    var name, response;
    if (yesAnswer) {
      name = verified ? "good" : "yes";
      response = buttonMultiplier + "y";
    } else {
      name = verified ? "bad" : "no";
      response = buttonMultiplier + "n";
    }

    return $("<a/>").html("&nbsp;")
                    .addClass(name + buttonMultiplier + "_button")
                    .addClass("button")
                    .click(function() {
                      $('.button', $(this).closest('.answer')).unbind('click');

                      answeredSoFarCount += 1;

                      progressCount.html(answeredSoFarCount == gameData.length ? "" : answeredSoFarCount + " / " + gameData.length);
                      progressSoFar.width((100 * answeredSoFarCount / gameData.length) + "%");

                      var transitionPause = animationTime * 1.5;
                      if (verified) transitionPause = animationTime * 2;

                      if (challenge || matchMe) {
                        transitionPause = 0;
                      } else {
                        var answer = $(this).closest(".answer");
                        if (verified) {
                          var result = combo.results ? "good" : "bad";
                          var guess = $(this).hasClass("good_button") ? "good" : "bad";
                          $("#" + guess + "_" + result).hide().detach().appendTo(answer).fadeIn();
                        } else {
                          $.each(['yes', 'no'], function() {
                            var result = combo.results[this];
                            if (this == name) result += 1;
                            var resultPercentage = (result / (combo.results.yes + combo.results.no + 1)) * 100;
                            if (resultPercentage == 0) resultPercentage += combo.choco;
                            else if (resultPercentage == 100) resultPercentage -= combo.choco;
                            if (resultPercentage > 0) {
                              $("<div/>")
                                .addClass('results')
                                .addClass(this.toString())
                                .appendTo(answer)
                                .animate({
                                  height: (resultPercentage * 2) + "px"
                                }, animationTime);
                            }
                          });
                        }
                      }

                      var rightPosition = container.outerWidth() + 100;
                      $(this).closest('.frame').animate({
                          left: 0
                        }, transitionPause).animate({
                          left: -1 * rightPosition
                        }, animationTime).next('.frame').show().animate({
                          left: rightPosition
                        }, transitionPause).animate({
                          left: 0
                        }, animationTime
                      );

                      var nextCombosLength = $(this).closest('.frame').nextAll('.frame').length;
                      self.postAnswer({comboId: combo.id, matchMeId: combo.match_me_id, otherPhotoId: combo.other_photo_id}, response, function(){
                        self.doDelayed(function() {
                          successFunction();
                          if (endlessGame && nextCombosLength < 20) {
                            self.getMoreCombos();
                          } else if (nextCombosLength == 1) {
                            goToAnswers(0)
                          }
                        }, transitionPause);
                      });
                    });
  }

  this.addCombo = function() {
    var successFunction = function() {
      trackingFunction(matchMe ? "/match_me/answers" : (challenge ? "/challenge/answers" : "/games/answers"));
    };

    var prompt = typeof(this.results) == "object" ?
      "Should we introduce these two?" :
      "We introduced them! What did they think?";

    if (challenge) prompt = "Would these two make a great match?";

    if (this.name) prompt = "Should we introduce " + this.opposite_sex + ' to ' + this.name + "?";

    var verified = !challenge && typeof this.results == "boolean";
    var useMultiplier = !verified && multiplier > 1;

    $("<div/>")
      .attr("id", "combo_" + (this.id || this.matchMeId))
      .addClass('frame')
      .addClass('combo')
      .css('left', container.outerWidth() + 100)
      .append(
        $("<div/>").addClass('photos')
                   .append(photo(this.one, this.two, this.one_interests, true))
                   .append(photo(this.two, this.one, this.two_interests, false))
      ).append("<div class='question'>" + prompt +"</div>")
       .append(
         $("<div/>").addClass('answer')
                    .addClass(useMultiplier ? 'multiplier' : null)
                    .append(useMultiplier ? button(this, verified, false, successFunction, multiplier) : null)
                    .append(button(this, verified, false, successFunction))
                    .append(button(this, verified, true, successFunction))
                    .append(useMultiplier ? button(this, verified, true, successFunction, multiplier) : null)
       ).append(
         useMultiplier ? $("<div/>").addClass("multiplier_message").addClass("small").html("You're seeing the new \"No/Yes x " + multiplier + "\" buttons because " + (multiplier == 2 ? "we now trust you as a matcher." : "you're matching so accurately.") + "<br/>They let you submit a yes or not vote that counts as " + multiplier + " votes instead of one. Use them wisely :)") : null
       ).append(
         $("<a/>").addClass("show_interests").html("hmm, tough one... show me their interests").click(function() {
           $(this).closest('.frame').find(".interests").toggleClass("hidden_interests");
         })
       ).insertBefore("#completed");
  };

  $('#completed').addClass('frame').css('left', container.outerWidth()).appendTo(container);

  $.each(gameData, addCombo);

  $($('.frame').get(0)).animate({left: 0}, animationTime);

  return this;
}
