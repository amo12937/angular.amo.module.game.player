"use strict"

do (moduleName = "amo.module.game.player") ->
  angular.module moduleName, ["ng"]
  .factory "#{moduleName}.Player", ->
    idSeed = 0
    (name, strategy) ->
      id = idSeed++
      id: -> id
      name: -> name
      changeStrategy: (newStrategy) ->
        strategy = newStrategy
        return
      select: (x) -> strategy.select? x
      play: -> strategy.play()

  .factory "#{moduleName}.strategy.Man", ["$q", ($q) ->
    (board) ->
      deferred = null
      select: (x) ->
        return false unless deferred and board.select x
        deferred.resolve board.isFinished()
        deferred = null
        return true
      play: ->
        unless deferred
          deferred = $q.defer()
        return deferred.promise
  ]

  .factory "#{moduleName}.strategy.Com.Base", [
    "$timeout"
    "$q"
    ($timeout, $q) ->
      (board, delay) ->
        self =
          delay: (d) ->
            return delay unless d
            delay = Math.max d, 0
            return self
          play: ->
            deferred = $q.defer()
            $timeout ->
              x = self.getChosen()
              if x is undefined or not board.select x
                throw new Error "getChosen must return the selectable obj on the board.\nyour choie: #{x}"
              deferred.resolve board.isFinished()
              return
            , delay
            return deferred.promise
  ]

  .factory "#{moduleName}.strategy.Com.AlphaBeta", [
    "#{moduleName}.strategy.Com.Base"
    (ComBase) ->
      (board, delay, maxDepth) ->
        getValue = (depth, a, b) ->
          turn = board.current.turn()
          return board.current.value turn if depth <= 0 or board.isFinished()
          for x in board.current.getSelectableList()
            board.select x
            v = -getValue depth - 1, -b, -a
            board.undo()
            if v > a
              a = v
            if a >= b
              # ここで返ってくるのは、評価値 a が b つまりひとつ上の -A を上回った場合 (a >= -A)
              # ひとつ上では、V (= -a) として V > A が評価されるが、a >= -A より V <= A だから
              # この V によって A が上書きされることはない。for 文を回して次の評価値 v2 を調べても
              # v より小さければ採択されず、大きければ上の V として採択されないので、これ以上
              # 調べても意味が無い。ゆえに、ここで返しても問題ない。
              return a
          return a
            
        self = ComBase board, delay
        self.maxDepth = (d) ->
          return maxDepth unless d
          maxDepth = Math.max d, 1
          return self
        self.getChosen = ->
          result = null
          a = -Infinity
          for x in board.current.getSelectableList()
            board.select x
            v = -getValue maxDepth, -Infinity, -a
            board.undo()
            if v > a
              a = v
              result = x
          return result
        return self
  ]

