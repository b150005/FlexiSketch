# FlexiSketch: Flutter Canvas Drawing Library

## 概要

FlexiSketch は、Flutter アプリケーション開発者向けの高機能かつ柔軟なキャンバス描画ライブラリです。
無限に拡大・縮小可能なキャンバスや多彩な描画ツールを提供し、直感的なユーザーインターフェースで複雑な描画機能を実現します。

## 機能

- フリーハンド描画
- 図形描画(四角形、円)
- 画像の追加
- 消しゴム
- 取り消し/やり直し
- カスタマイズ可能な保存機能

## 使用方法

### 基本的な使用方法

```dart
import 'package:flexi_sketch/flexi_sketch.dart';

class MyDrawingPage extends StatelessWidget {
  final controller = FlexiSketchController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlexiSketchWidget(
        controller: controller,
      ),
    );
  }
}
```

### 保存機能の設定

スケッチを画像またはデータとして保存するには、保存処理を設定します：

```dart
// コントローラーの初期化
final controller = FlexiSketchController();

// 画像として保存する処理の設定
controller.saveAsImage = (imageData) async {
  // 画像データ（Uint8List）を保存する処理
  await saveToGallery(imageData);
};

// データとして保存する処理の設定
controller.saveAsData = (data) async {
  // スケッチデータ（Map<String, dynamic>）を保存する処理
  await saveToCloud(data);
};
```

### エラーハンドリング

保存処理中のエラーは`FlexiSketchError`として捕捉できます：

```dart
try {
  await controller.handleSaveAsImage();
} on SaveHandlerNotSetError {
  // 保存処理が設定されていない場合
} on ImageGenerationError {
  // 画像の生成に失敗した場合
} on SaveError {
  // その他の保存エラーの場合
}
```

## ライセンス

[ライセンス形態を決定し記載]

## 開発者

[開発者または開発チームの情報]

## リポジトリ

[GitHub などのリポジトリ URL]

## ドキュメント

[詳細なドキュメントへのリンク]

## サポート

[サポートの方法や連絡先]

FlexiSketch - 柔軟で強力な描画機能を、あなたのアプリケーションに。

## TODO

### 機能追加

- スティッキーノート形式でテキストを挿入できるようにする
- 画像のクロップ(切り取り)ができるようにする
- 描画したオブジェクトのコピー&ペーストができるようにする
- 範囲選択が可能な選択ツールを実装する
- ペンで引いた線(直線・円)の近似線・図形を表示・置換できるようにする
