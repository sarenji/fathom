(function() {
  var Entity, Game, exports, filter, map, reduce;
  var __slice = Array.prototype.slice;
  map = function(array, callback) {
    var item, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = array.length; _i < _len; _i++) {
      item = array[_i];
      _results.push(callback(item));
    }
    return _results;
  };
  filter = function(array, callback) {
    var item;
    return [
      (function() {
        var _i, _len, _results;
        if (callback(item)) {
          _results = [];
          for (_i = 0, _len = array.length; _i < _len; _i++) {
            item = array[_i];
            _results.push(item);
          }
          return _results;
        }
      })()
    ];
  };
  reduce = function(array, callback, init) {
    var final, item, _i, _len, _results;
    if (init == null) {
      init = null;
    }
    final = init || array.shift();
    _results = [];
    for (_i = 0, _len = array.length; _i < _len; _i++) {
      item = array[_i];
      _results.push(final = callback(final, item));
    }
    return _results;
  };
  Game = (function() {
    function Game() {}
    Game.currentState = null;
    Game.switchState = function(state) {
      return this.currentState = state;
    };
    return Game;
  })();
  Entity = (function() {
    function Entity(x, y) {
      if (x == null) {
        x = 0;
      }
      if (y == null) {
        y = 0;
      }
      this.x = x;
      this.y = y;
      this.events = {};
      this;
    }
    Entity.prototype.on = function(event, callback) {
      this.events[event] = this.events[event] || [];
      this.events[event].push(callback);
      return this;
    };
    Entity.prototype.off = function(event, callback) {
      if (callback) {
        this.events[event] = filter(this.events[event], function(x) {
          return x === callback;
        });
      } else if (event) {
        delete this.events[event];
      }
      return this;
    };
    Entity.prototype.emit = function() {
      var args, event;
      event = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      this.events[event](args);
      return this;
    };
    return Entity;
  })();
  exports = module && module.exports || this;
  exports.Game = Game;
  exports.Entity;
}).call(this);
