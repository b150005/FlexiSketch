# FlexiSketch: Flutter Canvas Drawing Library

## 概要

FlexiSketch は、Flutter アプリケーション開発者向けの高機能かつ柔軟なキャンバス描画ライブラリです。
無限に拡大・縮小可能なキャンバスや多彩な描画ツールを提供し、直感的なユーザーインターフェースで複雑な描画機能を実現します。

## 機能

- 描画ツール
  - フリーハンド描画（ペン）
  - 図形描画（四角形、円）
  - 消しゴム
- 画像機能
  - 画像のアップロード
  - クリップボードからの画像貼り付け
- 編集機能
  - 元に戻す/やり直し
  - 全消去
- カスタマイズ
  - 色の選択（プリセットカラーパレット）
  - 線の太さ調整
- データ管理
  - PNG 画像としてエクスポート
  - JSON データとして保存/読み込み
- キーボードショートカット
  - Ctrl+Z: 元に戻す
  - Ctrl+Y/Ctrl+Shift+Z: やり直す
  - Ctrl+V: 画像貼り付け

## インストール

```yaml
dependencies:
  flexi_sketch: ^1.0.0 # バージョンは最新のものを指定してください
```

## 基本的な使用方法

```dart
import 'package:flexi_sketch/flexi_sketch.dart';

class MyDrawingPage extends StatelessWidget {
  const MyDrawingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlexiSketchWidget(
        // 画像として保存する処理
        onSaveAsImage: (imageData) async {
          // 画像データ（Uint8List）を処理
          await saveImageToGallery(imageData);
        },
        // データとして保存する処理
        onSaveAsData: (jsonData, imageData) async {
          // JSONデータと画像データを処理
          final imageUrl = await uploadImage(imageData);

          // メタデータを更新（画像URLを設定）
          final metadata = jsonData['metadata'] as Map<String, dynamic>;
          metadata['previewImageUrl'] = imageUrl;

          // 更新したJSONデータを保存
          await saveToCloud(jsonData);
        },
        // 初期データの読み込み
        data: initialData,
        // エラーハンドリング
        onError: (message) {
          showErrorDialog(context, message);
        },
      ),
    );
  }
}
```

## データ形式

### JSON データ構造

FlexiSketch で保存される JSON データは以下の構造を持ちます：

```json
{
  "metadata": {
    "id": "unique-id",
    "createdAt": "2024-11-12T10:32:37.303",
    "updatedAt": "2024-11-12T10:32:37.303",
    "title": "Sketch Title"
  },
  "content": {
    "version": 1,
    "canvas": {
      "width": 800,
      "height": 600
    },
    "objects": [
      // 描画オブジェクトの配列
    ]
  }
}
```

## エラーハンドリング

FlexiSketch は以下のエラー型を提供します：

```dart
try {
  // 保存処理など
} on SaveHandlerNotSetError {
  // 保存ハンドラが設定されていない場合
} on ImageGenerationError {
  // 画像生成に失敗した場合
} on DataGenerationError {
  // データ生成に失敗した場合
} on SaveError {
  // その他の保存関連エラー
} on FlexiSketchError {
  // その他のFlexiSketchエラー
}
```

## キーボードショートカット

| キー             | 機能         |
| ---------------- | ------------ |
| Ctrl + Z         | 元に戻す     |
| Ctrl + Shift + Z | やり直す     |
| Ctrl + Y         | やり直す     |
| Ctrl + V         | 画像貼り付け |

## TODO

### 機能追加予定

- スティッキーノート形式でのテキスト挿入
- 画像のクロップ機能
- オブジェクトのコピー&ペースト
- 範囲選択ツール
- ペンストロークの図形近似変換

### 改善予定

- ツールバーの表示/非表示制御の改善
- パフォーマンスの最適化
- モバイル対応の強化

## ライセンス

[ライセンス情報を追加]

## 貢献

バグ報告や機能要望は[Issues]()にて受け付けています。  
プルリクエストも歓迎です。

## サポート

ドキュメントやサポートについては[Wiki]()を参照してください。
