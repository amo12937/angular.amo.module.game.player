# angular.amo.module.game.player

ゲームのプレイヤーを表すクラス、及びそれに与える戦略クラスを提供する。

# インストール方法
```
bower install -S angular.amo.module.game.player
```

```haml:index:haml
%script(src="bower_components/angular.amo.module.game.player/dist/js/player.min.js")
```

# Player
player は、第1引数に name, 第2引数に strategy を渡すことで生成できる。

## player.play
1 回分の play を行い、game が終了したかどうか（またはその promise）を返す。  
実際の処理は strategy.play に移譲される

## player.select
player が人間だった場合に、人間の入力を受け取るためのインターフェース。  
実際の処理は strategy.select に移譲されるが、strategy が select メソッドを提供していない場合は単に無視される。

## player.id
player の固有の ID を返す。自動生成される。

## player.name
player 名を返す。player 名は 生成時の第1引数で与えられる。

## player.changeStrategy
player は、途中でその戦略を変更することが出来る。


# strategy.Man
人間を表す strategy  
ゲーム盤を表す board を第1引数に取る。

```coffee
man = Man board
```

## man.play
これは単に promise を返す。promise は、man.select で選択した値が board によって受理されることで解決される。

## man.select
人間の入力を受け取るメソッド。  
選択した値が board によって受理されたかどうかを返す


# strategy.Com.Base
コンピュータを表す strategy のベースクラス  
ゲーム盤を表す board、スピード調整のための delay を引数に取る。  
このクラス自体は抽象クラスで、子クラスで getChosen メソッドを実装する必要がある

## com.delay
getter / setter を兼ねている。delay を自由に変更できる。

## com.play
delay ミリ秒後に処理がはじまる。

## com.getChosen
board 上の選択可能な値の中から 1 つを選ぶメソッド。
ここで返ってきた値が board.select によって受理できなかった場合はエラーが発生する。
抽象メソッドで、strategy.Com.Base では実装されていない。


# strategy.Com.AlphaBeta
コンピュータを表す strategy で、アルゴリズムにアルファベータ法を使っている。

## com.maxDepth
探索深度を表す。これが大きいほどコンピュータは強くなるが、重くなる。

## com.getChosen
アルファベータ法による指し手の決定を行う。


# board の仕様
ゲーム盤を表す board インスタンスには、次のメソッドが実装されている必要がある。

| method | required | description |
|:-------|:---------|:------------|
| select | o | 値の選択。選択が正しくできた場合に true, そうでない場合に false を返す |
| isFinished | o | ゲームが終了したかどうかを返す |

## strategy.Com.AlphaBeta を使用する場合
strategy.Com.AlphaBeta を使用する場合はさらに以下のメソッドが必要である。

| method | required | description |
|:-------|:---------|:------------|
| current.turn | o | 現在の手番を表す値を返す |
| current.value | o | 現在の手番を表す値を受け取り、その player にとっての評価値を返す |
| current.getSelectableList | o | 現在の選択可能な値のリストを返す |
| undo | o | 選択の取り消しを行う |

