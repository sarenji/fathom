(function() {
  var Fathom, assert, fathom, should;
  assert = require("assert");
  should = require("should");
  fathom = require("../fathom.js");
  Fathom = fathom.Fathom;
  module.exports = {
    'test Game': function() {
      var game;
      game = new Fathom.Game();
      return should.not.exist(game.currentState);
    }
  };
}).call(this);
