describe('Game', function () {
  var gameData = [
    {one: "/assets/cow.jpg", two: "/assets/bug.jpg", one_interests: "", two_interests: "", id: 1, results: {yes: 3, no: 7}, choco: 13},
    {one: "/assets/dog.jpg", two: "/assets/building.jpg", one_interests: "", two_interests: "", id: 2, results: {yes: 840, no: 160}, choco: 19},
    {one: "/assets/bug.jpg", two: "/assets/cow.jpg", one_interests: "", two_interests: "", id: 3, results: true, choco: 19}
  ];

  var game;

  afterEach(function() {
    $('#jasmine_content').hide();
  });

  beforeEach(function() {
    $('#jasmine_content').empty();
    $('#jasmine_content').show();
    $('#jasmine_content').append("<div id='container'></div><div id='completed'>Completed</div>");
    this.addMatchers({
      toRoughlyEqual: function(expected) {
        if (expected == 0 && this.actual < 0.0001 && this.actual > -0.0001) return true;
        var ratio = (this.actual / expected);
        return ratio < 1.02 && ratio > 0.98
      }
    });
  });

  describe('Game Setup', function() {

    beforeEach(function() {
      game = startGame(1, gameData, false, function(){});
    });

    it('should create combos', function() {
      expect($('.combo').length).toEqual(3);
    });

    it('should have two images on each combo', function() {
      var combos = $('.combo');
      $.each(combos, function() {
        expect($('.photo', this).length).toEqual(2);
      });
    });

    xit('should center images vertically', function() {
      var firstPhoto = $('.combo:first .photo:last');
      waitsFor(3000, function(){
        return firstPhoto.css("margin-top") != "0px"
      }), "expected margin-top to be set";
      runs(function(){
        expect(firstPhoto.css("margin-top")).toEqual("119.5px");
      });
    });


    it('should hide both combos to start', function() {
      var combos = $('.combo');
      $.each(combos, function() {
        expect($(this).position().left).toRoughlyEqual(1050);
      })
    });
  });

  describe('Game Play', function() {
    var displayedCombo;

    beforeEach(function() {
      game = startGame(1, gameData, false, function() {}, 0);
      displayedCombo = $('.combo:first');
    });

    it('should show the first combo after a delay', function() {
      expect(displayedCombo.position().left).toRoughlyEqual(0);
    });


    describe("answer button", function() {

      var postAnswerSpy;
      var setLocationSpy;
      beforeEach(function() {
        postAnswerSpy = spyOn(game, "postAnswer");
        setLocationSpy = spyOn(game, "setLocation");
      });

      it('should only allow one click per answer', function() {
        expect(postAnswerSpy).wasNotCalled();
        $('.yes_button', displayedCombo).click();
        expect(postAnswerSpy.callCount).toEqual(1);
        $('.yes_button', displayedCombo).click();
        expect(postAnswerSpy.callCount).toEqual(1);
        $('.no_button', displayedCombo).click();
        expect(postAnswerSpy.callCount).toEqual(1);

        var nextCombo = displayedCombo.next('.combo');
        $('.no_button', nextCombo).click();
        expect(postAnswerSpy.callCount).toEqual(2);
        $('.no_button', nextCombo).click();
        expect(postAnswerSpy.callCount).toEqual(2);
        $('.yes_button', nextCombo).click();
        expect(postAnswerSpy.callCount).toEqual(2);
      });


      it('should send a yes answer to the server when yes button is clicked', function() {
        expect(postAnswerSpy).wasNotCalled();
        $('.yes_button', displayedCombo).click();
        expect(postAnswerSpy).wasCalledWith({comboId: 1, matchMeId: undefined, otherPhotoId: undefined}, "y", jasmine.any(Function));
      });

      it('should send a no answer to the server when no button is clicked', function() {
        expect(postAnswerSpy).wasNotCalled();
        $('.no_button', displayedCombo).click();
        expect(postAnswerSpy).wasCalledWith({comboId: 1, matchMeId: undefined, otherPhotoId: undefined}, "n", jasmine.any(Function));
      });

      it('should reveal results from others', function() {
        $('.yes_button', displayedCombo).click();
        expect($('.yes', displayedCombo).height()).toRoughlyEqual((((3 + 1) / (3 + 7 + 1)) * 100) * 2);
      });

      describe("training result", function(){
        var trainingCombo;
        beforeEach(function(){
          trainingCombo = $('.combo:last');
        });
        it('should not reveal results from others', function() {
          $('.yes_button', trainingCombo).click();
          expect($('.yes', trainingCombo).height()).toEqual(null);
        });
        it('should reveal your result', function() {
          $('.no_button', trainingCombo).click();
          //wrong!
        });
      });

      it('should reveal the next combo', function() {
        var nextDisplayedCombo = $('.combo:nth-child(2)');
        expect(displayedCombo.position().left).toRoughlyEqual(0);
        expect(nextDisplayedCombo.position().left).toRoughlyEqual(1050);
        $('.no_button', displayedCombo).click();
        expect(nextDisplayedCombo.position().left).toRoughlyEqual(0);
        expect(displayedCombo.position().left).toRoughlyEqual(-1050);
      });
      
      it('should show a completed message and redirect to the games page if no combos are left and gender is set', function() {
        var doDelayedSpy = spyOn(game, "doDelayed");

        $('.combo:first .yes_button').click();
        $('.combo:last .bad_button').click();
        var messageCombo = $('.frame:last');
        expect(messageCombo.position().left).toRoughlyEqual(0);
        expect(messageCombo.html()).toContain("Completed")

        postAnswerSpy.mostRecentCall.args[2]();

        // transition delay
        expect(doDelayedSpy).wasCalledWith(jasmine.any(Function), 0);
        doDelayedSpy.mostRecentCall.args[0]();

        // wait to change page delay
        expect(doDelayedSpy).wasCalledWith(jasmine.any(Function), 0);
        doDelayedSpy.mostRecentCall.args[0]();

        expect(setLocationSpy).wasCalledWith("/games");
      });

      it('should show a completed message but not redirect to the answers page if no combos are left and help_request has been set', function() {
        $('#completed').addClass('help_request');

        var doDelayedSpy = spyOn(game, "doDelayed");

        $('.combo:first .yes_button').click();
        $('.combo:last .bad_button').click();
        var messageCombo = $('.frame:last');
        expect(messageCombo.position().left).toRoughlyEqual(0);
        expect(messageCombo.html()).toContain("Completed")

        postAnswerSpy.mostRecentCall.args[2]();

        // transition delay
        expect(doDelayedSpy).wasCalledWith(jasmine.any(Function), 0);
        doDelayedSpy.mostRecentCall.args[0]();

        // wait to change page delay
        expect(doDelayedSpy).wasCalledWith(jasmine.any(Function), 0);
        doDelayedSpy.mostRecentCall.args[0]();

        expect(setLocationSpy).wasNotCalled();
      });

      it('should show a completed message and do a custom redirect if x-data-post-game-location is set', function() {
        $('#completed').attr('x-data-post-game-location', '/after-game');

        var doDelayedSpy = spyOn(game, "doDelayed");

        $('.combo:first .yes_button').click();
        $('.combo:last .bad_button').click();
        var messageCombo = $('.frame:last');
        expect(messageCombo.position().left).toRoughlyEqual(0);
        expect(messageCombo.html()).toContain("Completed")

        postAnswerSpy.mostRecentCall.args[2]();

        // transition delay
        expect(doDelayedSpy).wasCalledWith(jasmine.any(Function), 0);
        doDelayedSpy.mostRecentCall.args[0]();

        // wait to change page delay
        expect(doDelayedSpy).wasCalledWith(jasmine.any(Function), 0);
        doDelayedSpy.mostRecentCall.args[0]();

        expect(setLocationSpy).wasCalledWith('/after-game');
      });

    });

    describe("ajax", function(){
      var ajaxSpy;
      beforeEach(function() {
        ajaxSpy = spyOn($, "ajax");
      });

      it("should post answers to the server", function() {
        var successFunction = function() {};

        game.postAnswer({comboId: 99, matchMeId: undefined, otherPhotoId: undefined}, "y", successFunction);

        expect(ajaxSpy).wasCalledWith({
          type: 'POST',
          url: '/games/1/answers',
          data: {
            answer: {
              combo_id: 99, answer: 'y'
            }
          },
          success: successFunction
        });
      });

      it("should post answers to the server for MatchMe", function() {
        var successFunction = function() {};

        game.postAnswer({comboId: undefined, matchMeId: 19, otherPhotoId: 7, game: "match_me"}, "y", successFunction);

        expect(ajaxSpy).wasCalledWith({
          type: 'POST',
          url: '/match_me/19/games/1/answers',
          data: {
            answer: {
              other_photo_id: 7, answer: 'y', game: "match_me"
            }
          },
          success: successFunction
        });
      });

      it("should queue answers and request a game id from the server when gameid null", function() {
        game = startGame(null, gameData, false, function() {}, 0);

        game.postAnswer({comboId: 99, matchMeId: undefined, otherPhotoId: undefined}, "y", null);
        game.postAnswer({comboId: 100, matchMeId: undefined, otherPhotoId: undefined}, "n", function() {});

        expect(ajaxSpy).wasCalledWith({
          type: 'POST',
          dataType: "json",
          url: '/games',
          data: {},
          success: jasmine.any(Function)
        });
        
        expect(ajaxSpy.callCount).toEqual(1);

        ajaxSpy.mostRecentCall.args[0].success({id: 9});
        expect(ajaxSpy.callCount).toEqual(3);

        expect(ajaxSpy.argsForCall[1][0]).toEqual({
          type: 'POST',
          url: '/games/9/answers',
          data: {
            answer: {
              combo_id: 99, answer: 'y'
            }
          },
          success: null
        });

        expect(ajaxSpy.argsForCall[2][0]).toEqual({
          type: 'POST',
          url: '/games/9/answers',
          data: {
            answer: {
              combo_id: 100, answer: 'n'
            }
          },
          success: jasmine.any(Function)
        });

      });
    });

  });

  describe("Choco Game", function() {
    var chocoGameData;
    var chocoGame;
    var chocoCombo;
    beforeEach(function() {
      chocoGameData = [{one: "/assets/cow.jpg", two: "/assets/bug.jpg", one_interests: "", two_interests: "", id: 1, results: {yes: 0, no: 7}, choco: 13}];
      chocoGame = startGame(1, chocoGameData, false, function() {}, 0);
      chocoCombo = $('.combo:first');
    });

    it("should reveal results from others with choco if everyone's are unanimous", function() {
      $('.no_button', chocoCombo).click();
      expect($('.no', chocoCombo).height()).toRoughlyEqual((100 - 13) * 2);
    });

  });

  describe('Endless Game', function() {
    var displayedCombo;

    beforeEach(function() {
      game = startGame(1, gameData, true, function() {}, 0);
      displayedCombo = $('.combo:first');
    });

    it('should show the first combo after a delay', function() {
      expect(displayedCombo.position().left).toRoughlyEqual(0);
    });
  });

  describe('Challenge Game', function() {
    var game;
    var displayedCombo;

    beforeEach(function() {
      $('#jasmine_content').append("<div style='width: 600px;'><div id='progress_so_far'></div></div>");
      game = startGame(1, gameData, true, function() {}, 0, true);
      displayedCombo = $('.combo:first');
    });

    describe("answer button", function() {

      var postAnswerSpy;
      var setLocationSpy;
      beforeEach(function() {
        postAnswerSpy = spyOn(game, "postAnswer");
        setLocationSpy = spyOn(game, "setLocation");
      });

      it('should not reveal results from others', function() {
        $('.yes_button', displayedCombo).click();
        expect($('.yes', displayedCombo).height()).toRoughlyEqual(0);
      });

      it('should set the progress width', function() {
        $('.yes_button', displayedCombo).click();
        expect($('#progress_so_far').width()).toRoughlyEqual(600/3);
      });

      it('should send a yes answer to the server when yes button is clicked', function() {
        expect(postAnswerSpy).wasNotCalled();
        $('.yes_button', displayedCombo).click();
        expect(postAnswerSpy).wasCalledWith({comboId: 1, matchMeId: undefined, otherPhotoId: undefined}, "y", jasmine.any(Function));
      });

      it('should reveal the next combo', function() {
        var nextDisplayedCombo = $('.combo:nth-child(2)');
        expect(displayedCombo.position().left).toRoughlyEqual(0);
        expect(nextDisplayedCombo.position().left).toRoughlyEqual(1050);
        $('.no_button', displayedCombo).click();
        expect(nextDisplayedCombo.position().left).toRoughlyEqual(0);
        expect(displayedCombo.position().left).toRoughlyEqual(-1050);
      });

    });
  });

  describe('Match Me', function() {
    var game;
    var displayedCombo;

    beforeEach(function() {
      gameData.unshift({one: "/assets/bug.jpg", two: "/assets/cow.jpg", one_interests: "", two_interests: "", match_me_id: 12, other_photo_id: 34, results: {yes: 3, no: 7}, choco: 13});
      game = startGame(1, gameData, true, function() {}, 0, true);
      displayedCombo = $('.combo:first');
    });

    describe("answer button", function() {

      var postAnswerSpy;
      var setLocationSpy;
      beforeEach(function() {
        postAnswerSpy = spyOn(game, "postAnswer");
        setLocationSpy = spyOn(game, "setLocation");
      });

      it('should send a yes answer to the server when yes button is clicked', function() {
        expect(postAnswerSpy).wasNotCalled();
        $('.yes_button', displayedCombo).click();
        expect(postAnswerSpy).wasCalledWith({comboId: undefined, matchMeId: 12, otherPhotoId: 34}, "y", jasmine.any(Function));
      });

      it('should reveal the next combo', function() {
        var nextDisplayedCombo = $('.combo:nth-child(2)');
        expect(displayedCombo.position().left).toRoughlyEqual(0);
        expect(nextDisplayedCombo.position().left).toRoughlyEqual(1050);
        $('.no_button', displayedCombo).click();
        expect(nextDisplayedCombo.position().left).toRoughlyEqual(0);
        expect(displayedCombo.position().left).toRoughlyEqual(-1050);
      });

    });
  });

});
