"use strict"

do (amo = @[".amo"], moduleName = "amo.module.game.player") ->
  describe "#{moduleName} の仕様", ->
    beforeEach module moduleName

    describe "#{moduleName}.Player の仕様", ->
      Player = null
      name = "hoge"
      strategy =
        play: -> 1
      another =
        name: "fuga"
        strategy:
          play: -> 2
      player = null
      beforeEach inject ["#{moduleName}.Player", (_Player) ->
        Player = _Player
        player = Player name, strategy
      ]
      it "id は生成するたびインクリメントされる", ->
        expect(player.id()).toBe 0
        player = Player another.name, another.strategy
        expect(player.id()).toBe 1

      it "name は渡した値がそのまま変える", ->
        expect(player.name()).toBe name

      it "select は strategy.select を呼び出す", ->
        strategy.select = jasmine.createSpy "select"
        expected = {}
        player.select expected
        expect(strategy.select).toHaveBeenCalledWith expected

      it "play は strategy.play を呼び出す", ->
        spyOn strategy, "play"
        player.play()
        expect(strategy.play).toHaveBeenCalled()

      it "play は strategy.play の返り値をそのまま返す", ->
        expected = {}
        spyOn(strategy, "play").and.returnValue expected
        actual = player.play()
        expect(actual).toBe expected

      it "changeStrategy によって戦略を変える事ができる", ->
        expect(player.play()).toBe 1
        player.changeStrategy another.strategy
        expect(player.play()).toBe 2

      describe "strategy の仕様", ->
        it "strategy.select は任意である", ->
          expect(-> player.select {}).not.toThrow()
        it "strategy.play は必須である", ->
          delete strategy.play
          expect(-> player.play()).toThrow()

    describe "#{moduleName}.strategy.Man の仕様", ->
      $rootScope = null
      man = null
      board = null

      beforeEach inject [
        "$rootScope"
        "#{moduleName}.strategy.Man"
        (_$rootScope, Man) ->
          $rootScope = _$rootScope
          board = jasmine.createSpyObj "board", [
            "select"
            "isFinished"
          ]
          man = Man board
      ]

      it "play のあとに select を呼び出すと board.select に第1引数が渡される", ->
        expected = {}
        man.play()
        man.select expected
        expect(board.select).toHaveBeenCalledWith expected

      it "play の前に select を呼び出しても board.select は呼び出されない", ->
        man.select {}
        expect(board.select).not.toHaveBeenCalled()

      it "board.select が true を返した場合、board.isFinished が呼ばれる", ->
        board.select.and.returnValue true
        man.play()
        man.select {}
        expect(board.isFinished).toHaveBeenCalled()

      it "board.select が false を返した場合、board.isFinished は呼ばれない", ->
        board.select.and.returnValue false
        man.play()
        man.select {}
        expect(board.isFinished).not.toHaveBeenCalled()

      it "play は promise を返し、board.isFinished が返した値をそのまま返す", (done) ->
        expected = {}
        board.select.and.returnValue true
        board.isFinished.and.returnValue expected
        man.play().then (actual) ->
          expect(actual).toBe expected
          done()
        man.select {}
        $rootScope.$digest()

      it "受理されるまで select でき、それ以降は受理されない", ->
        board.select.and.callFake (n) -> n >= 3
        man.play()

        man.select 1
        man.select 2
        man.select 3
        expect(board.select.calls.count()).toBe 3
        man.select 4
        expect(board.select.calls.count()).toBe 3

      describe "board の仕様", ->
        it "board.select は必須である", ->
          delete board.select
          man.play()
          expect(-> man.select {}).toThrow()

        it "board.isFinished は必須である", ->
          board.select.and.returnValue true
          delete board.isFinished
          man.play()
          expect(-> man.select {}).toThrow()

    describe "#{moduleName}.strategy.Com.Base の仕様", ->
      $timeout = null
      $rootScope = null
      board = null
      com = null
      delay = 100
      another =
        delay: 200

      beforeEach ->
        module ["$provide", ($provide) ->
          decorator = amo.test.helper.jasmine.spyOnDecorator spyOn
          $provide.decorator "$timeout", decorator
          return
        ]
        inject [
          "$timeout", "$rootScope", "#{moduleName}.strategy.Com.Base"
          (_$timeout, _$rootScope, ComBase) ->
            $timeout = _$timeout
            $rootScope = _$rootScope
            board = jasmine.createSpyObj "board", [
              "select"
              "isFinished"
            ]
            com = ComBase board, delay
            com.getChosen = jasmine.createSpy "com.getChosen"
        ]

      it "delay はコンピュータの応答時間を返す", ->
        expect(com.delay()).toBe delay

      it "delay に値を渡すとその値にセットされ、com 自身が返る", ->
        expect(com.delay another.delay).toBe com
        expect(com.delay()).toBe another.delay

      it "play を実行すると delay 秒後に関数が実行される", ->
        com.play()
        expect($timeout).toHaveBeenCalledWith jasmine.any(Function), delay

      it "$timeout.flush 時、com.getChosen() が 値を返さないと例外が発生する", ->
        board.select.and.returnValue true
        com.play()
        expect(-> $timeout.flush()).toThrow()

      it "$timeout.flush 時、com.getChosen() が返す値を board.select が受理出来ないと例外が発生する", ->
        com.getChosen.and.returnValue {}
        board.select.and.returnValue false
        com.play()
        expect(-> $timeout.flush()).toThrow()

      it "$timeout.flush 時、com.getChosen() が返す値を board.select が受理すると、board.isFinished が呼ばれる", ->
        com.getChosen.and.returnValue {}
        board.select.and.returnValue true
        com.play()
        $timeout.flush()
        expect(board.isFinished).toHaveBeenCalled()

      it "play は promise を返し、board.isFinished が返す値を使って解決される", (done) ->
        com.getChosen.and.returnValue {}
        board.select.and.returnValue true
        expected = {}
        board.isFinished.and.returnValue expected
        com.play().then (actual) ->
          expect(actual).toBe expected
          done()
        $timeout.flush()

      describe "strategy.Com.Base の子クラスの仕様", ->
        it "getChosen は必須である", ->
          delete com.getChosen
          board.select.and.returnValue true
          board.isFinished.and.returnValue {}
          com.play()
          expect(-> $timeout.flush()).toThrow()

      describe "board の仕様", ->
        it "board.select は必須である", ->
          com.getChosen.and.returnValue {}
          delete board.select
          board.isFinished.and.returnValue {}
          com.play()
          expect(-> $timeout.flush()).toThrow()

        it "board.isFinished は必須である", ->
          com.getChosen.and.returnValue {}
          board.select.and.returnValue true
          delete board.isFinished
          com.play()
          expect(-> $timeout.flush()).toThrow()

    describe "#{moduleName}.strategy.Com.AlphaBeta の仕様", ->
      describe "AlphaBeta クラスの仕様", ->
        ComBase = null
        AlphaBeta = null
        maxDepth = 2
        another =
          maxDepth: 5
  
        beforeEach ->
          module ["$provide", ($provide) ->
            decorator = amo.test.helper.jasmine.spyOnDecorator spyOn
            $provide.decorator "#{moduleName}.strategy.Com.Base", decorator
            return
          ]
          inject [
            "#{moduleName}.strategy.Com.Base"
            "#{moduleName}.strategy.Com.AlphaBeta"
            (_ComBase, _AlphaBeta) ->
              ComBase = _ComBase
              AlphaBeta = _AlphaBeta
          ]
  
        it "ComBase を継承している", ->
          board = {}
          delay = 100
          expected = {}
          ComBase.and.returnValue expected
          com = AlphaBeta board, delay, maxDepth
          expect(ComBase).toHaveBeenCalledWith board, delay
          expect(com).toBe expected

        it "maxDepth はコンピュータの読みの深さを返す", ->
          com = AlphaBeta {}, 100, maxDepth
          expect(com.maxDepth()).toBe maxDepth

        it "maxDepth に値を渡すとその値にセットされ、com 自身が返る", ->
          com = AlphaBeta {}, 100, maxDepth
          expect(com.maxDepth another.maxDepth).toBe com
          expect(com.maxDepth()).toBe another.maxDepth

      describe "getChosen の挙動", ->
        ab = null
        board = null
        delay = 100
        maxDepth = 2
        runWithDataProvider = amo.test.helper.runWithDataProvider
        beforeEach inject ["#{moduleName}.strategy.Com.AlphaBeta", (AlphaBeta) ->
          board = do ->
            tree = [8, 15, 5, 11, 20, 21, 23, 2, 0, 7, 13, 6, 3, 1, 4, 26, 17, 14, 25, 22, 12, 19, 10, 16, 24, 9, 18]
            turn = 1
            depth = 0
            pos = 0
            f = (name, func) -> jasmine.createSpy(name).and.callFake func
            self =
              select: f "board.select", (n) ->
                pos = pos * 3 + n
                depth++
                turn *= -1
              undo: f "board.undo", ->
                pos = pos // 3
                depth--
                turn *= -1
              isFinished: f "board.isFinished", -> depth >= 3
              current:
                turn: f "board.current.turn", -> turn
                value: f "board.current.value", -> self.dummy.returnedValue turn * tree[pos]
                getSelectableList: f "board.current.getSelectableList", -> [0, 1, 2]
              dummy:
                returnedValue: f "board.dummy.returnedValue", (n) -> (n)
          ab = AlphaBeta board, delay, maxDepth
        ]

        it "19 が採択される", ->
          # 自分のターン
          expect(ab.getChosen()).toBe 2
          board.select 2

          # 相手のターン
          expect(ab.getChosen()).toBe 1
          board.select 1

          # 自分のターン
          expect(ab.getChosen()).toBe 0
          board.select 0

          # 相手のターン
          turn = board.current.turn()
          value = board.current.value turn
          expect(value).toBe -19 # 負号は相手のターンのため

        it "枝切を行う", ->
          # はじめの 3 つ： 8, 15, 5 のうち、自分の手番なので最大値 15 が採択される。
          # 次は 11, 20, 21 であるが、20 が評価された時点で次のような枝切が発生する：
          # 自分の手番なので最大値が採択される。今評価しているのが 20 なので、最大値は 20 よりも多い。
          # 一つ上の階層では、相手の手番なので最小値が採択される。20 よりも小さい 15 がすでに候補にあるため、
          # 20 より大きい値を返しても採択されることはない。よって、次の値（21）を評価する必要は無い
          ab.getChosen()
          calledDataProvider = -> [
            8, 15, 5, 11, 20, 23, 7, 13, 6, 25, 22, 12, 19, 10, 16, 24
          ].map (n) -> [-n]
          calledRunBlock = (n) ->
            expect(board.dummy.returnedValue).toHaveBeenCalledWith n
          runWithDataProvider calledDataProvider, calledRunBlock

          uncalledDataProvider = -> [
            21, 2, 0, 3, 1, 4, 26, 17, 14, 9, 18
          ].map (n) -> [-n]
          uncalledRunBlock = (n) ->
            expect(board.dummy.returnedValue).not.toHaveBeenCalledWith n
          runWithDataProvider uncalledDataProvider, uncalledRunBlock

        it "select が呼ばれる階数と undo が呼ばれる階数は一致する", ->
          ab.getChosen()
          expect(board.select.calls.count() - board.undo.calls.count()).toBe 0

