(function() {
  var assert, fathom, should;
  assert = require("assert");
  should = require("should");
  fathom = require("../index.js");
  module.exports = {
    'test Game': function() {
      var game;
      game = new fathom.Game();
      return should.not.exist(game.currentState);
    }
  };
}).call(this);
