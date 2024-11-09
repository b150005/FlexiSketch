import 'dart:typed_data';

/// スケッチを画像として保存する処理を定義するコールバック型
///
/// 画像データを生成し、その保存処理を実行します。
/// 処理が成功した場合は正常終了し、失敗した場合は例外をスローします。
typedef SaveSketchAsImage = Future<void> Function(Uint8List imageData);

/// スケッチをデータとして保存する処理を定義するコールバック型
///
/// スケッチのデータを保存する処理を実行します。
/// 処理が成功した場合は正常終了し、失敗した場合は例外をスローします。
typedef SaveSketchAsData = Future<void> Function(Map<String, dynamic> data);