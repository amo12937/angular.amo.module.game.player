(function() {
  "use strict";
  (function(moduleName) {
    return angular.module(moduleName, ["ng"]).factory("" + moduleName + ".Player", function() {
      var idSeed;
      idSeed = 0;
      return function(name, strategy) {
        var id;
        id = idSeed++;
        return {
          id: function() {
            return id;
          },
          name: function() {
            return name;
          },
          changeStrategy: function(newStrategy) {
            strategy = newStrategy;
          },
          select: function(x) {
            return typeof strategy.select === "function" ? strategy.select(x) : void 0;
          },
          play: function() {
            return strategy.play();
          }
        };
      };
    }).factory("" + moduleName + ".strategy.Man", [
      "$q", function($q) {
        return function(board) {
          var deferred;
          deferred = null;
          return {
            select: function(x) {
              if (!(deferred && board.select(x))) {
                return false;
              }
              deferred.resolve(board.isFinished());
              deferred = null;
              return true;
            },
            play: function() {
              if (!deferred) {
                deferred = $q.defer();
              }
              return deferred.promise;
            }
          };
        };
      }
    ]).factory("" + moduleName + ".strategy.Com.Base", [
      "$timeout", "$q", function($timeout, $q) {
        return function(board, delay) {
          var self;
          return self = {
            delay: function(d) {
              if (!d) {
                return delay;
              }
              delay = Math.max(d, 0);
              return self;
            },
            play: function() {
              var deferred;
              deferred = $q.defer();
              $timeout(function() {
                var x;
                x = self.getChosen();
                if (x === void 0 || !board.select(x)) {
                  throw new Error("getChosen must return the selectable obj on the board.\nyour choie: " + x);
                }
                deferred.resolve(board.isFinished());
              }, delay);
              return deferred.promise;
            }
          };
        };
      }
    ]).factory("" + moduleName + ".strategy.Com.AlphaBeta", [
      "" + moduleName + ".strategy.Com.Base", function(ComBase) {
        return function(board, delay, maxDepth) {
          var getValue, self;
          getValue = function(depth, a, b) {
            var turn, v, x, _i, _len, _ref;
            turn = board.current.turn();
            if (depth <= 0 || board.isFinished()) {
              return board.current.value(turn);
            }
            _ref = board.current.getSelectableList();
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              x = _ref[_i];
              board.select(x);
              v = -getValue(depth - 1, -b, -a);
              board.undo();
              if (v > a) {
                a = v;
              }
              if (a >= b) {
                return a;
              }
            }
            return a;
          };
          self = ComBase(board, delay);
          self.maxDepth = function(d) {
            if (!d) {
              return maxDepth;
            }
            maxDepth = Math.max(d, 1);
            return self;
          };
          self.getChosen = function() {
            var a, result, v, x, _i, _len, _ref;
            result = null;
            a = -Infinity;
            _ref = board.current.getSelectableList();
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              x = _ref[_i];
              board.select(x);
              v = -getValue(maxDepth, -Infinity, -a);
              board.undo();
              if (v > a) {
                a = v;
                result = x;
              }
            }
            return result;
          };
          return self;
        };
      }
    ]);
  })("amo.module.game.player");

}).call(this);
