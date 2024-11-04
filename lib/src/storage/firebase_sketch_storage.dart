// import 'package:flutter/material.dart';

// import '../objects/drawable_object.dart';
// import '../objects/image_object.dart';
// import '../objects/path_object.dart';
// import '../objects/shape_object.dart';
// import 'sketch_storage.dart';

// /// Firebaseを使用したスケッチストレージの実装
// class FirebaseSketchStorage implements SketchStorage {
//   final FirebaseFirestore _firestore;
//   final FirebaseStorage _storage;
//   final String _userId;
//   final ThumbnailGenerator _thumbnailGenerator;

//   FirebaseSketchStorage({
//     required String userId,
//     required ThumbnailGenerator thumbnailGenerator,
//     FirebaseFirestore? firestore,
//     FirebaseStorage? storage,
//   })  : _userId = userId,
//         _thumbnailGenerator = thumbnailGenerator,
//         _firestore = firestore ?? FirebaseFirestore.instance,
//         _storage = storage ?? FirebaseStorage.instance;

//   /// スケッチデータのコレクションへの参照を取得
//   CollectionReference<Map<String, dynamic>> get _sketchesCollection =>
//       _firestore.collection('users').doc(_userId).collection('sketches');

//   @override
//   Future<SketchMetadata> saveSketch(SketchData data, {bool asImage = false}) async {
//     final batch = _firestore.batch();
//     final metadata = data.metadata.copyWith(updatedAt: DateTime.now());
//     final docRef = _sketchesCollection.doc(metadata.id);

//     // プレビュー画像とサムネイルを生成
//     final previewImage = await _thumbnailGenerator.generatePreview(
//       data.objects,
//       const Size(800, 600),
//     );
//     final thumbnailImage = await _thumbnailGenerator.generateThumbnail(
//       data.objects,
//       const Size(200, 150),
//     );

//     // 画像をStorageにアップロード
//     final previewRef =
//         _storage.ref().child('users').child(_userId).child('sketches').child(metadata.id).child('preview.png');
//     final thumbnailRef =
//         _storage.ref().child('users').child(_userId).child('sketches').child(metadata.id).child('thumbnail.png');

//     await Future.wait([
//       previewRef.putData(previewImage),
//       thumbnailRef.putData(thumbnailImage),
//     ]);

//     final previewUrl = await previewRef.getDownloadURL();
//     final thumbnailUrl = await thumbnailRef.getDownloadURL();

//     final updatedMetadata = metadata.copyWith(
//       previewImageUrl: previewUrl,
//       thumbnailUrl: thumbnailUrl,
//     );

//     // メタデータを保存
//     batch.set(docRef, updatedMetadata.toJson());

//     if (!asImage) {
//       // オブジェクトデータを保存（画像として保存する場合は不要）
//       final objectsData = data.objects.map((obj) => obj.toJson()).toList();
//       batch.set(
//         docRef.collection('data').doc('objects'),
//         {'objects': objectsData},
//       );
//     }

//     await batch.commit();
//     return updatedMetadata;
//   }

//   @override
//   Future<SketchData> loadSketch(String id) async {
//     final docSnapshot = await _sketchesCollection.doc(id).get();
//     if (!docSnapshot.exists) {
//       throw Exception('Sketch not found: $id');
//     }

//     final metadata = SketchMetadata.fromJson(docSnapshot.data()!);
//     final objectsDoc = await docSnapshot.reference.collection('data').doc('objects').get();

//     if (!objectsDoc.exists) {
//       throw Exception('Sketch data not found: $id');
//     }

//     final objectsData = objectsDoc.data()!['objects'] as List<dynamic>;
//     final objects = await Future.wait(
//       objectsData.map((data) => _deserializeObject(data as Map<String, dynamic>)),
//     );

//     return SketchData(metadata: metadata, objects: objects);
//   }

//   @override
//   Future<List<SketchMetadata>> listSketches() async {
//     final querySnapshot = await _sketchesCollection.orderBy('updatedAt', descending: true).get();

//     return querySnapshot.docs.map((doc) => SketchMetadata.fromJson(doc.data())).toList();
//   }

//   @override
//   Future<void> deleteSketch(String id) async {
//     final batch = _firestore.batch();
//     final docRef = _sketchesCollection.doc(id);

//     // Storageの画像を削除
//     final previewRef = _storage.ref().child('users').child(_userId).child('sketches').child(id).child('preview.png');
//     final thumbnailRef =
//         _storage.ref().child('users').child(_userId).child('sketches').child(id).child('thumbnail.png');

//     await Future.wait([
//       previewRef.delete(),
//       thumbnailRef.delete(),
//     ]);

//     // Firestoreのデータを削除
//     batch.delete(docRef);
//     batch.delete(docRef.collection('data').doc('objects'));

//     await batch.commit();
//   }

//   Future<DrawableObject> _deserializeObject(Map<String, dynamic> data) async {
//     final type = data['type'] as String;
//     switch (type) {
//       case 'PathObject':
//         return PathObject.fromJson(data);
//       case 'ShapeObject':
//         return ShapeObject.fromJson(data);
//       case 'ImageObject':
//         return await ImageObject.fromJson(data);
//       default:
//         throw Exception('Unknown object type: $type');
//     }
//   }
// }
