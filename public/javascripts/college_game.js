function calculateDimensions(width, height, maxWidth, maxHeight) {
  var widthRatio = maxWidth / width;
  var heightRatio = maxHeight / height;
  var minRatio = Math.min(widthRatio, heightRatio);
  return {height: height * minRatio, width: width * minRatio}
}

BADGE_INFO = {
"5_correct_badge": {
    name: "Newbie Matchmaker",
    description: "I'm like a freshman taking my first class. I still get nervous when I raise my hand.",
    message: "<p>Good job!  You're quickly becoming the teacher's pet.  You've correctly identified 5 verified matches.</p>",
    nextMessage: "<p>Correctly identify 15 more verified matches to become a Junior Matchmaker!</p>",
    nextBadge: "20_correct_badge"
  },
  "20_correct_badge": {
    name: "Junior Matchmaker",
    description: "No more hazing for me. I've shown enough skill that they stopped laughing at me (for now).",
    message: "<p>Keep it up!  You're not as bad as we thought.  You've correctly identified 20 verified matches!</p>",
    nextMessage: "<p>Correctly identify 30 more verified matches to become an Amateur Matchmaker!</p>",
    nextBadge: "50_correct_badge"
  },
  "50_correct_badge": {
    name: "Amateur Matchmaker",
    description: "My grades are suffering, but my matchmaking is improving!",
    message: "<p>Keep skipping class!  You have the right priorities.  You've correctly identified 50 verified matches!",
    nextMessage: "<p>Correctly identify 50 more verified matches to become an Apprentice Matchmaker!</p>",
    nextBadge: "100_correct_badge"
  },
  "100_correct_badge": {
    name: "Apprentice Matchmaker",
    description: "Matchmaking is in my blood (or is that alcohol?!?!)",
    message: "<p>Don't drink and match!  Your focus and clarity have been outstanding.  You've correctly identified 100 verified matches!",
    nextMessage: "<p>Correctly identify 150 more verified matches to become a Matchmaker!</p>",
    nextBadge: "250_correct_badge"
  },
  "250_correct_badge": {
    name: "Matchmaker",
    description: "I'm a bonefide matchmaker! I don't know what that means, but it sounds really good!",
    message: "<p>Now go forth and procreate!  Your savvy with the opposite sex is amazing.  You've correctly identified 250 verified matches!",
    nextMessage: "<p>Correctly identify 250 more verified matches to become a Professional Matchmaker!</p>",
    nextBadge: "500_correct_badge"
  },
  "500_correct_badge": {
    name: "Professional Matchmaker",
    description: "Forget this whole college thing, my career should be in matchmaking!",
    message: "<p>Step up your game!  This ain't the minor leagues anymore, kid.  You've correctly identified 500 verified matches!",
    nextMessage: "<p>Correctly identify 500 more verified matches to become an Expert Matchmaker!</p>",
    nextBadge: "1000_correct_badge"
  },
  "1000_correct_badge": {
    name: "Expert Matchmaker",
    description: "I'm obsessed, but that's OK!",
    message: "<p>Don't stop now!  Pair up your whole freaking school.  You've correctly identified 1000 verified matches!",
    nextMessage: "<p>Correctly identify 4000 more verified matches to become a Grand Master Matchmaker!</p>",
    nextBadge: "5000_correct_badge"
  },
  "5000_correct_badge": {
    name: "Grand Master Matchmaker",
    description: "They made this title up just for me.",
    message: "<p>Why are you still here?  You should have started your own matchmaking service by now.  You've correctly identified 5000 verified matches!"
  },
  "5_streak_badge": {
    name: "Lucky Streak",
    description: "If you see me in class, rub me for good luck!  I’m on a Lucky Streak in The Matching Game!",
    message: "You’re on a roll!  You’ve correctly identified 5 verified matches in a row!",
    nextMessage: "Correctly identify 5 more verified matches in a row to earn the Super Lucky Streak badge!",
    nextBadge: "10_streak_badge"
  },
  "10_streak_badge": {
    name: "Super Lucky Streak",
    description: "It’s time I asked out that hottie (you know who you are)!  I’m on a crazy Lucky Streak in The Matching Game!",
    message: "Keep it up!  You’ve correctly identified 10 verified matches in a row!",
    nextMessage: "Correctly identify 10 more verified matches in a row to earn the Super Duper Lucky Streak badge!",
    nextBadge: "20_streak_badge"
  },
  "20_streak_badge": {
    name: "Super Duper Lucky Streak",
    description: "If I were this lucky in love, I’d be dating someone rich and famous right now (i.e not you!).  I’m on an amazing Lucky Streak in The Matching Game!",
    message: "Impressive!  You’ve correctly identified 20 verified matches in a row!",
    nextMessage: "Correctly identify 30 more verified matches in a row to earn the Somewhat Suspicious Super Duper Streak badge!",
    nextBadge: "50_streak_badge"
  },
  "50_streak_badge": {
    name: "Somewhat Suspicious Super Duper Lucky Streak",
    description: "I’ve been banned from Vegas, but not The Matching Game (yet)!  I’m on an unbelievable Lucky Streak in The Matching Game!",
    message: "Keep defying the odds!  You’ve correctly identified 50 verified matches in a row!"
  }
}

function badgesForCount(count) {
  var levels = [5000, 1000, 500, 250, 100, 50, 20, 5];
  var out = []
  $.each(levels, function(index, level) {
    if (count >= level) {
      out.push(level + "_correct_badge");
    }
  });
  return out;
}

function badgeForStreak(count) {
  var streaks = [50, 20, 10, 5];
  var out = []
  $.each(streaks, function(index, streak) {
    if (count == streak) {
      out.push(streak + "_streak_badge");
    }
  });
  return out[0];
}


function startCollegeGame(id, gameData, existingBadges) {
  var self = this;
  self.gameId = id;
  if (!existingBadges) existingBadges = [];

  var leftContainer = $("#photos .left_photo .image");
  var rightContainer = $("#photos .right_photo .image");
  var results = $(".good_bad_votes");
  var goodVotes = $(".good_bad_votes .good_votes");
  var badVotes = $(".good_bad_votes .bad_votes");
  var resultsPhotoOne = $(".good_bad_votes .photo_one");
  var resultsPhotoTwo = $(".good_bad_votes .photo_two");
  var voteButtons = $("#buttons .vote_buttons");
  var shareOrNext = $("#buttons .share_or_next");

  this.loadPhoto = function(src, onload) {
    if ($("#photo_cache img[src$='" + src + "']").length > 0) return;
    $("#photo_cache").append(
      $("<img/>").attr("src", src).load(onload).click(function() {
        $.facebox({ image: src.replace(/normal/, 'large') });
      })
    );
  };

  this.addPhoto = function(src, interests, container) {
    container.append($("#photo_cache img[src$='" + src + "']"));
    if (interests.length <= 3) interests = "No interests provided." 
    container.siblings(".interests").html(interests);
  };

  this.resizePhoto = function(photo, container) {
    var maxWidth = $(container).width();
    var maxHeight = $(container).height();
    var width = $(photo).width();
    var height = $(photo).height();

    var dimensions = calculateDimensions(width, height, maxWidth, maxHeight);
    $(photo).width(dimensions.width);
    $(photo).height(dimensions.height);
    var margin = (maxHeight - dimensions.height) / 2;
    $(photo).css("marginTop", margin)
            .css("marginBottom", margin);
  };

  this.showCombo = function(combo) {
    leftContainer.html("");
    rightContainer.html("");
    self.addPhoto(combo.one, combo.one_interests, leftContainer);
    self.addPhoto(combo.two, combo.two_interests, rightContainer);
    voteButtons.show();
    shareOrNext.hide();
  };

  this.showResults = function(combo, yesAnswer) {
    var badge;
    if (!combo.college_id && combo.verified) {
      this.showVerifiedResults(combo, yesAnswer);
      badge = self.updateCounts(true, combo.results == yesAnswer);
    } else {
      this.showUnverifiedResults(combo, yesAnswer);
      self.updateCounts(false);
    }

    results.show();
    self.showResultsPhoto(combo.one, resultsPhotoOne);
    self.showResultsPhoto(combo.two, resultsPhotoTwo);
    return badge;
  };

  this.showUnverifiedResults = function(combo, yesAnswer) {
    var yes = combo.cresults.yes;
    var no = combo.cresults.no;
    yesAnswer ? yes += 1 : no += 1;
    var yesPercent = 100 * yes / (yes + no);
    if (yesPercent < 70) yesPercent += combo.choco;
    else yesPercent -= combo.choco;
    goodVotes.width("0%").animate({width: yesPercent + "%"});
    badVotes.width("0%").animate({width: (100 - yesPercent) + "%"});
    results.find(".verified_results").hide()
    results.find(".unverified_results").show()
  };

  this.showVerifiedResults = function(combo, yesAnswer) {
    results.find(".unverified_results").hide()
    results.find(".verified_results .result_message").hide();
    results.find(".verified_results ." + combo.results + "_" + yesAnswer).show()
    results.find(".verified_results").show()
  };

  this.showResultsPhoto = function(src, container) {
    container.html("");
    var photo = $("img[src$='" + src + "']")[0];
    self.resizePhoto(photo, container);
    container.append(photo);
  };

  this.setBadges = function(lastAnswerCorrect) {
    var existingBadges = self.getBadges();

    $("#badges").empty();
    var badges = self.determineBadges(lastAnswerCorrect);
    $.each(badges, function(index, badge) {
      $("#badges").append($("<img>").attr("class", "badge").attr("src", "/images/badges/" + badge + ".png"));
    });
    
    var newBadges = self.getBadges();
    $.each(existingBadges, function(index, existingBadge) {
      newBadges = $.grep(newBadges, function(newBadge) {
        return newBadge != existingBadge;
      });
    });
    return newBadges.length == 0 ? null : newBadges[0];
  }

  this.getBadges = function() {
    var badges = [];
    $.each($("#badges img"), function(index, badgeImage) {
      badges.push(badgeImage.src.slice(badgeImage.src.indexOf("/badges/") + 8, badgeImage.src.indexOf(".png")));
    });
    return badges;
  }

  this.updateCounts = function(verified, correct) {
    var stats = $(".player_stats");
    var voteCount = stats.find(".vote_count");
    voteCount.html(parseInt(voteCount.html()) + 1);

    if (verified) {
      var verifiedCount = stats.find(".verified_count");
      verifiedCount.html(parseInt(verifiedCount.html()) + 1);

      verifiedBucket = stats.find((correct ? ".correct" : ".incorrect") + "_count");
      verifiedBucket.html(parseInt(verifiedBucket.html()) + 1);

      var accuracy = Math.ceil(100 * parseInt(stats.find(".correct_count").html()) / parseInt(verifiedCount.html()));
      stats.find(".accuracy").html(accuracy);
      return self.setBadges(correct);
    }

    return;
  };

  var combo = gameData[0];
  this.loadPhoto(combo.one, function () {
    self.addPhoto(combo.one, combo.one_interests, leftContainer);
    self.resizePhoto(this, leftContainer);
  });
  this.loadPhoto(combo.two, function() {
    self.resizePhoto(this, rightContainer);
    self.addPhoto(combo.two, combo.two_interests, rightContainer);
    $.each(gameData, function () {
      self.loadPhoto(this.one, function () { self.resizePhoto(this, leftContainer); });
      self.loadPhoto(this.two, function () { self.resizePhoto(this, rightContainer); });
    });
  });

  this.showCongratulations = function(badge) {
    rightContainer.html("");
    var congrats = $("<div/>").addClass("congratulations").addClass("small");
    rightContainer.append(congrats);
    congrats.append($("<h3/>").html("Congratulations!"));
    congrats.append($("<img/>").attr("src", "/images/badges/" + badge + ".png"));
    congrats.append($("<div/>").html(BADGE_INFO[badge].message));

    var nextBadge = $("<div/>").addClass("congratulations").addClass("small");
    leftContainer.append(nextBadge);
    nextBadge.append($("<h3/>").html("Earn Your Next Badge"));
    nextBadge.append($("<div/>").html(BADGE_INFO[badge].nextMessage));
    nextBadge.append($("<img/>").attr("src", "/images/badges/" + BADGE_INFO[badge].nextBadge + ".png"));

    leftContainer.siblings(".interests").html("");
    rightContainer.siblings(".interests").html("");

    voteButtons.hide();
    shareOrNext.show();

    self.shareBadge(badge)
  }

  this.shareBadge = function(badge) {
    baseHref = location.href.replace(/\/college.*/, "/college");
    var faceboxDialogUrl = [];
    faceboxDialogUrl.push("http://www.facebook.com/dialog/feed");
    faceboxDialogUrl.push("?app_id=" + window.fbAppId);
    faceboxDialogUrl.push("&link=https://apps.facebook.com/thematchinggame");
    faceboxDialogUrl.push("&picture=http://www.thematchinggame.com/images/badges/" + badge + ".png");
    faceboxDialogUrl.push("&name=" + BADGE_INFO[badge].name);
    faceboxDialogUrl.push("&caption=" + USER_NAME + " earned the " + BADGE_INFO[badge].name + " badge.");
    faceboxDialogUrl.push("&description=" + BADGE_INFO[badge].description);
    faceboxDialogUrl.push("&message=Im killing it on The Mathing Game. Just earned my " + BADGE_INFO[badge].name + " badge!");
    faceboxDialogUrl.push("&redirect_uri=" + baseHref + "/close");

    window.open(faceboxDialogUrl.join("").replace(/\s/ig, "%20"), 'shareBadgeWindow', "width=1000,height=420,toolbar=no,location=no,scrollbars=no,menubar=no,screenY=750");
  }

  var nextCombo = 1;
  this.clickAnswerButton = function() {
    var button = $(this);
    var good = (button.attr("src").indexOf("good") > -1);
    $(".last_vote").html(good ? "Good" : "Bad");
    var currentCombo = gameData[nextCombo - 1];
    var badge = self.showResults(currentCombo, good);
    self.postResponse(currentCombo.id, (good ? "y" : "n"), badge);
    if (badge) {
      self.showCongratulations(badge);
      $("#buttons .share_badge").click(function() { self.shareBadge(badge) });
      $("#buttons .continue_playing").click(function() {
        self.showCombo(gameData[nextCombo]);
        nextCombo += 1;
      });
    } else {
      self.showCombo(gameData[nextCombo]);
      nextCombo += 1;      
    }
  };
  $("#buttons .match_button").click(this.clickAnswerButton);

  this.postResponse = function(comboId, response, badge) {
    $.ajax({
      type: 'POST',
      url: "/games/" + self.gameId + "/answers",
      data: {
        answer: {
          combo_id: comboId,
          answer: response
        },
        badge: badge
      }
    });

    if (nextCombo > gameData.length - 10) {
      self.getMoreCombos();
    }
  }

  this.getMoreCombos = function() {
    var comboIds = []
    for (var i=gameData.length - 1; i>gameData.length - 50 && i>=0; --i) {
      comboIds.push(gameData[i].id)
    }

    $.ajax({
      type: 'POST',
      url: "/games/" + self.gameId + "/more_combos",
      dataType: "json",
      data: {excluded_ids:comboIds, college:1},
      success: function(response) {
        gameData = gameData.concat(response);
        $.each(response, function () {
          self.loadPhoto(this.one, function () { self.resizePhoto(this, leftContainer); });
          self.loadPhoto(this.two, function () { self.resizePhoto(this, rightContainer); });
        });
      }
    })
  }

  var correctStreak = 0;
  this.determineBadges = function(lastAnswerCorrect) {
    var badges = [];

    if (lastAnswerCorrect) {
      correctStreak += 1;
    } else {
      correctStreak = 0;
    }
    $(".player_stats .streak_count").html(correctStreak);
    var streakBadge = badgeForStreak(correctStreak);
    if (streakBadge) {
      badges.push(streakBadge);
      existingBadges.unshift(streakBadge);
    }

    var countBadges = badgesForCount(parseInt($(".player_stats .correct_count").html()))
    badges.push(countBadges.shift());
    badges = badges.concat(existingBadges);
    badges = badges.concat(countBadges);

    return $.unique($.grep(badges, function(badge) { return badge; })).reverse();
  }

  self.setBadges(false);

  return this;
}
