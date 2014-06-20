// Generated by CoffeeScript 1.7.1
(function() {
  define(["js/app/slide", "js/app/slidepair"], function(Slide, SlidePair) {
    var Model;
    Model = (function() {
      Model.buildModelFromConfigurationObject = function(configObj) {
        var leftProps, leftSlide, model, pair, pairs, rightProps, rightSlide, _i, _len, _ref;
        pairs = [];
        _ref = configObj.pairs;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          pair = _ref[_i];
          leftProps = pair.left;
          rightProps = pair.right;
          leftSlide = new Slide(Slide.SIDES.LEFT, leftProps.image, leftProps.title, leftProps.details, leftProps.fontColor);
          rightSlide = new Slide(Slide.SIDES.RIGHT, rightProps.image, rightProps.title, rightProps.details, rightProps.fontColor);
          pair = new SlidePair(leftSlide, rightSlide);
          pairs.push(pair);
        }
        model = new Model(pairs, configObj.imageDimensions.width, configObj.imageDimensions.height);
        return model;
      };

      function Model(pairs, imageWidth, imageHeight) {
        this.pairs = pairs;
        this.imageWidth = imageWidth;
        this.imageHeight = imageHeight;
        this.activePairIndex = 0;
      }

      Model.prototype.getActivePair = function() {
        return this.pairs[this.activePairIndex];
      };

      Model.prototype.advanceToNextPair = function() {
        this.activePairIndex++;
        if (this.activePairIndex >= this.pairs.length) {
          return this.activePairIndex = 0;
        }
      };

      Model.prototype.debug = function() {
        var i, pair, _i, _len, _ref;
        console.log("###### model with [" + this.pairs.length + "] pairs #####");
        console.log("imageWidth: [" + this.imageWidth + "]");
        console.log("imageHeight: [" + this.imageHeight + "]");
        _ref = this.pairs;
        for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
          pair = _ref[i];
          console.log("[" + i + "]: " + pair);
        }
        return console.log("############## done ##########");
      };

      return Model;

    })();
    return Model;
  });

}).call(this);