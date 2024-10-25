// 履歴エントリの型定義
import '../objects/drawable_object.dart';

enum HistoryEntryType {
  draw,
  erase,
  clear,
}

class HistoryEntry {
  final List<DrawableObject> objects;
  final HistoryEntryType type;

  HistoryEntry({
    required this.objects,
    required this.type,
  });
}
