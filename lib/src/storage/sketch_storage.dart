// lib/src/storage/sketch_storage.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../objects/drawable_object.dart';

/// スケッチのメタデータを表すクラス
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

  const SketchMetadata({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.title,
    this.previewImageUrl,
    this.thumbnailUrl,
  });

  factory SketchMetadata.create(String title) {
    return SketchMetadata(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      title: title,
    );
  }

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'title': title,
        'previewImageUrl': previewImageUrl,
        'thumbnailUrl': thumbnailUrl,
      };

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
class SketchData {
  /// スケッチのメタデータ
  final SketchMetadata metadata;

  /// 描画オブジェクトのリスト
  final List<DrawableObject> objects;

  const SketchData({
    required this.metadata,
    required this.objects,
  });
}

/// スケッチの保存方法を定義するインターフェース
abstract class SketchStorage {
  /// スケッチを保存する
  ///
  /// [data] 保存するスケッチデータ
  /// [asImage] 画像として保存するかどうか
  Future<SketchMetadata> saveSketch(SketchData data, {bool asImage = false});

  /// スケッチを読み込む
  ///
  /// [id] 読み込むスケッチのID
  Future<SketchData> loadSketch(String id);

  /// スケッチの一覧を取得する
  Future<List<SketchMetadata>> listSketches();

  /// スケッチを削除する
  ///
  /// [id] 削除するスケッチのID
  Future<void> deleteSketch(String id);
}

/// スケッチのサムネイル生成方法を定義するインターフェース
abstract class ThumbnailGenerator {
  /// プレビュー画像を生成する
  ///
  /// [objects] サムネイルを生成する対象のオブジェクトリスト
  /// [size] 生成するサムネイルのサイズ
  Future<Uint8List> generatePreview(List<DrawableObject> objects, Size size);

  /// サムネイル画像を生成する
  ///
  /// [objects] サムネイルを生成する対象のオブジェクトリスト
  /// [size] 生成するサムネイルのサイズ
  Future<Uint8List> generateThumbnail(List<DrawableObject> objects, Size size);
}
