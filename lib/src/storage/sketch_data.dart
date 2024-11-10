import '../objects/drawable_object.dart';

/// スケッチのメタデータを表すクラス
///
/// スケッチの識別情報、作成・更新日時、タイトル、
/// およびプレビュー・サムネイル画像のURLを管理します。
class SketchMetadata {
  /// スケッチの一意識別子
  final String id;

  /// スケッチの作成日時
  final DateTime createdAt;

  /// スケッチの更新日時
  final DateTime updatedAt;

  /// スケッチのタイトル
  final String title;

  /// プレビュー画像のURL
  final String? previewImageUrl;

  /// サムネイル画像のURL
  final String? thumbnailUrl;

  /// スケッチメタデータを作成します
  ///
  /// すべての必須フィールドを指定する必要があります。
  /// プレビューとサムネイルのURLはオプションです。
  const SketchMetadata({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.title,
    this.previewImageUrl,
    this.thumbnailUrl,
  });

  /// タイトルを指定して新しいスケッチメタデータを作成します
  ///
  /// ID、作成日時、更新日時は自動的に生成されます。
  /// [title] スケッチのタイトル
  /// Returns: 新しいスケッチメタデータインスタンス
  factory SketchMetadata.create(String title) {
    return SketchMetadata(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      title: title,
    );
  }

  /// 既存のメタデータを元に、指定されたフィールドを更新した新しいインスタンスを作成します
  ///
  /// null が指定されたフィールドは現在の値が維持されます。
  /// [id] 新しいID（オプション）
  /// [createdAt] 新しい作成日時（オプション）
  /// [updatedAt] 新しい更新日時（オプション）
  /// [title] 新しいタイトル（オプション）
  /// [previewImageUrl] 新しいプレビュー画像URL（オプション）
  /// [thumbnailUrl] 新しいサムネイル画像URL（オプション）
  /// Returns: 更新されたメタデータを持つ新しいインスタンス
  SketchMetadata copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? title,
    String? previewImageUrl,
    String? thumbnailUrl,
  }) {
    return SketchMetadata(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      title: title ?? this.title,
      previewImageUrl: previewImageUrl ?? this.previewImageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }

  /// メタデータをJSON形式に変換します
  ///
  /// 日時はISO 8601形式の文字列として保存されます。
  /// Returns: JSON形式のマップ
  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'title': title,
        'previewImageUrl': previewImageUrl,
        'thumbnailUrl': thumbnailUrl,
      };

  /// JSON形式のデータからメタデータインスタンスを作成します
  ///
  /// [json] メタデータを含むJSON形式のマップ
  /// Returns: 新しいメタデータインスタンス
  /// Throws: FormatException 日時の文字列が不正な場合
  factory SketchMetadata.fromJson(Map<String, dynamic> json) {
    return SketchMetadata(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      title: json['title'] as String,
      previewImageUrl: json['previewImageUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }
}

/// スケッチデータを表すクラス
///
/// メタデータと描画オブジェクトのリストをカプセル化します。
/// このクラスはスケッチの完全な状態を表現し、保存や読み込みの
/// 単位として使用されます。
class SketchData {
  /// スケッチのメタデータ
  final SketchMetadata metadata;

  /// 描画オブジェクトのリスト
  ///
  /// スケッチを構成する全ての描画可能なオブジェクトを含みます。
  /// オブジェクトの順序は描画順序を表します（先頭が最背面）。
  final List<DrawableObject> objects;

  /// スケッチデータを作成します
  ///
  /// [metadata] スケッチのメタデータ
  /// [objects] 描画オブジェクトのリスト
  const SketchData({
    required this.metadata,
    required this.objects,
  });
}
