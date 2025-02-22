import '../objects/drawable_object.dart';

/// 履歴エントリの操作種別
///
/// キャンバス上で実行可能な各種操作を表現します。
enum HistoryEntryType {
  /// オブジェクトの描画
  ///
  /// パス(線)や図形などの新規描画操作を表します。
  draw,

  /// オブジェクトの消去
  ///
  /// 消しゴムツールによる消去操作を表します。
  erase,

  /// キャンバスのクリア
  ///
  /// すべてのオブジェクトを削除する操作を表します。
  clear,

  /// オブジェクトの貼り付け
  ///
  /// 画像の貼り付けなどの操作を表します。
  paste,

  /// オブジェクトの削除
  ///
  /// 選択したオブジェクトの削除操作を表します。
  delete,

  /// オブジェクトの変形
  ///
  /// 選択したオブジェクトの移動・回転・スケール操作を表します。
  transform,
}

/// オブジェクトの操作履歴を表現するエントリ
///
/// 描画キャンバス上でのオブジェクトの追加、削除、消去などの操作履歴を保持するためのクラスです。
/// [FlexiSketchController]の元に戻す(undo), やり直す(redo)機能で使用されます。
///
/// 各エントリは操作時点でのオブジェクトの状態のスナップショットと、実行された操作の種類([type])を保持します。
class HistoryEntry {
  /// 操作時点でのオブジェクトのスナップショット
  ///
  /// キャンバス上の全オブジェクトの状態を表すリストです。
  /// 元に戻す・やり直し操作時にこの状態に復元されます。
  final List<DrawableObject> objects;

  /// 履歴エントリの種類
  ///
  /// どのような操作が行われたかを示します。
  final HistoryEntryType type;

  /// 新しい履歴エントリを作成します
  ///
  /// [objects] 操作時点でのオブジェクトのスナップショット
  /// [type] 実行された操作の種類
  HistoryEntry({
    required this.objects,
    required this.type,
  });
}
