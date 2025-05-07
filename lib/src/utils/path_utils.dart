import 'dart:ui';

class PathUtils {
  /// 点と線分の距離を計算するヘルパーメソッド
  static double distanceToLine(Offset point, Offset lineStart, Offset lineEnd) {
    // 線分の長さの二乗
    final double lineLength2 = (lineEnd - lineStart).distanceSquared;

    if (lineLength2 < 0.0001) {
      // 始点と終点がほぼ同じ場合、点と始点の距離を返す
      return (point - lineStart).distance;
    }

    // 線分上の最も近い点のパラメータt (0.0 <= t <= 1.0)
    final double t =
        ((point - lineStart).dx * (lineEnd - lineStart).dx + (point - lineStart).dy * (lineEnd - lineStart).dy) /
            lineLength2;

    if (t < 0.0) {
      // 最も近い点が線分の始点より前にある場合
      return (point - lineStart).distance;
    } else if (t > 1.0) {
      // 最も近い点が線分の終点より後にある場合
      return (point - lineEnd).distance;
    }

    // 線分上の最も近い点
    final Offset projection = lineStart + (lineEnd - lineStart) * t;

    // 点と最も近い点の距離
    return (point - projection).distance;
  }
}
