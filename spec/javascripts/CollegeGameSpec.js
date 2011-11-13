describe('CollegeGame', function () {

  describe("calculateDimensions", function() {

    it("should calculate the width and height based on maximums", function() {
      var actual = calculateDimensions(100, 100, 80, 80);
      expect(actual.width).toEqual(80);
      expect(actual.height).toEqual(80);
    });

    it("should calculate the width and height based on minimum ratio", function() {
      var actual = calculateDimensions(100, 200, 80, 80);
      expect(actual.width).toEqual(40);
      expect(actual.height).toEqual(80);
    });

    it("should calculate the width and height based even with different maximums", function() {
      var actual = calculateDimensions(100, 200, 80, 160);
      expect(actual.width).toEqual(80);
      expect(actual.height).toEqual(160);
    });

  });

  describe("badgeForCount", function() {
    it("return leveled badges",function() {
      expect(badgesForCount(21)).toEqual(["20_correct_badge", "5_correct_badge"]);
      expect(badgesForCount(3)).toEqual([]);
      expect(badgesForCount(5)).toEqual(["5_correct_badge"]);
      expect(badgesForCount(49)).toEqual(["20_correct_badge", "5_correct_badge"]);
      expect(badgesForCount(50)).toEqual(["50_correct_badge", "20_correct_badge", "5_correct_badge"]);
      expect(badgesForCount(51)).toEqual(["50_correct_badge", "20_correct_badge", "5_correct_badge"]);
    });
  });

  describe("startCollegeGame", function() {
    var gameData = [
      {one: "/public/assets/cow.jpg", two: "/public/assets/bug.jpg", one_interests: "", two_interests: "", id: 1, cresults: {yes: 3, no: 7}, choco: 13},
      {one: "/public/assets/dog.jpg", two: "/public/assets/building.jpg", one_interests: "", two_interests: "", id: 2, cresults: {yes: 840, no: 160}, choco: 19},
      {one: "/public/assets/bug.jpg", two: "/public/assets/cow.jpg", one_interests: "", two_interests: "", id: 3, cresults: true, choco: 19}
    ];

    var game;

    afterEach(function() {
      $('#jasmine_content').hide();
    });

    beforeEach(function() {
      window.USER_NAME = "NAME"
      $('#jasmine_content').empty();
      $('#jasmine_content').show();
      $('#jasmine_content').append("<div id='photo_cache'></div><div id='photos'><div class='left_photo'><div class='image'></div></div><div class='right_photo'><div class='image'></div></div></div><div id='buttons'><div class='match_button bad_match' src='college/bad_match_button.png'></div><div class='match_button good_match' src='college/good_match_button.png'></div>");
      $('#jasmine_content').append("<div id='buttons'><div class='vote_buttons'></div><div class='share_or_next'><div class='continue_playing'></div></div></div>");
      $('#jasmine_content').append("<div class='player_stats'><div class='correct_count'>49</div></div>");
      $('#jasmine_content').append("<div id='badges'></div>");
      this.addMatchers({
        toRoughlyEqual: function(expected) {
          if (expected == 0 && this.actual < 0.0001 && this.actual > -0.0001) return true;
          var ratio = (this.actual / expected);
          return ratio < 1.02 && ratio > 0.98
        }
      });
    });

    it("loads photos", function() {
      startCollegeGame(null, gameData);

      expect($("#photo_cache img").length).toEqual(2);
      expect($($("#photo_cache img")[0]).attr("src")).toEqual("/public/assets/cow.jpg");
      expect($($("#photo_cache img")[1]).attr("src")).toEqual("/public/assets/bug.jpg");
    });

    it("resizes photos", function() {
      $("#photos .left_photo .image").width(200)
      $("#photos .left_photo .image").height(200)
      startCollegeGame(null, gameData);

      expect($("#photo_cache img").length).toEqual(2);

      waitsFor(function() {
        return $($("#photos .left_photo .image img")[0]).width() > 0;
      });

      runs(function() {
        expect($($("#photos .left_photo .image img")[0]).width()).toEqual(200);
        expect($($("#photos .left_photo .image img")[0]).height()).toEqual(93);
        expect($($("#photos .left_photo .image img")[0]).css("marginTop")).toEqual("53.6667px");
        expect($($("#photos .left_photo .image img")[0]).css("marginBottom")).toEqual("53.6667px");
      });
    });

    it("should not load a photo that's already in the photo_cache", function() {
      game = startCollegeGame(null, gameData);

      game.loadPhoto(gameData[0].one);
      game.loadPhoto(gameData[0].one);

      expect($("#photo_cache img").length).toEqual(2);
    });

    it("doesn't show more than one photo in the visible containers", function () {
      game = startCollegeGame(null, gameData);
      game.showCombo(gameData[0]);

      expect($("#photos .left_photo .image img").length).toEqual(1);
      expect($("#photos .right_photo .image img").length).toEqual(1);

      game.loadPhoto(gameData[1].one);
      game.loadPhoto(gameData[1].two);
      game.showCombo(gameData[1]);

      expect($("#photos .left_photo .image img").length).toEqual(1);
      expect($("#photos .right_photo .image img").length).toEqual(1);
    });

    it("loads the next combo when you click on the answer button", function() {
      game = startCollegeGame(null, gameData);

      game.loadPhoto(gameData[1].one);
      game.loadPhoto(gameData[1].two);
      expect($("#photo_cache img").length).toEqual(4);

      $($("#buttons .match_button")[0]).click();
      expect($($("#photos .left_photo .image img")[0]).attr("src")).toEqual("/public/assets/dog.jpg");
      expect($($("#photos .right_photo .image img")[0]).attr("src")).toEqual("/public/assets/building.jpg");
    });

    describe("badges", function() {
      it("sets the correct badge on load", function() {
        game = startCollegeGame(null, gameData);
        expect($(".player_stats .correct_count").text()).toEqual("49");

        expect($(".badge").length).toEqual(2);
        expect($($(".badge")[0]).attr("src")).toContain("/20_correct_badge.png");
      });

      it("sets the correct badge after update", function() {
        game = startCollegeGame(null, gameData);
        game.updateCounts(true, true);
        expect($(".player_stats .correct_count").text()).toEqual("50");

        expect($(".badge").length).toEqual(3);
        expect($($(".badge")[0]).attr("src")).toContain("/50_correct_badge.png");

        game.updateCounts(true, true); 

        expect($(".badge").length).toEqual(3);
        expect($($(".badge")[0]).attr("src")).toContain("/50_correct_badge.png");
      });

      it("respects existing badges", function () {
        game = startCollegeGame(null, gameData, ["20_correct_badge", "5_streak_badge", "5_correct_badge"]);
        expect($(".player_stats .correct_count").text()).toEqual("49");

        expect($(".badge").length).toEqual(3);
        expect($($(".badge")[0]).attr("src")).toContain("/20_correct_badge.png");
        expect($($(".badge")[1]).attr("src")).toContain("/5_streak_badge.png");
        expect($($(".badge")[2]).attr("src")).toContain("/5_correct_badge.png");
      });


      describe("interestial badge presentation", function() {
        windowOpenedCalled = false;

        beforeEach(function() {
          window.open = function() { windowOpenedCalled = true };
          gameData[0].verified = true
          gameData[0].results = true
          game = startCollegeGame(null, gameData);

          $("#buttons .good_match").click();

          waitsFor(function() {
            return $("#photos .right_photo .image").text().indexOf("Congratulations") > -1;
          });
        })

        it("shows an interstitial instead of photos when you get a new badge", function() {
          runs(function() {
            expect($("#photos .right_photo .image").html()).toContain("/50_correct_badge");
            expect(windowOpenedCalled).toEqual(true);
            expect($("#photos .left_photo .image").html()).toContain("/100_correct_badge");
            expect($(".vote_buttons").css("display")).toEqual("none");
            expect($(".share_or_next").css("display")).toEqual("block");
          });
        })

        it("allows you to continue playing the game after the interstitial", function() {
          $("#buttons .continue_playing").click();
          waitsFor(function() {
            return $(".vote_buttons").css("display") == "block"
          })

          runs(function() {
            expect($(".share_or_next").css("display")).toEqual("none");
            expect($("#photos .right_photo .image").html()).toNotContain("/50_correct_badge");
          });
        })
      })
    });
  });

});
