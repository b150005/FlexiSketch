import 'package:flutter/material.dart';

import '../storage/sketch_storage.dart';
import 'sketch_thumbnail.dart';

/// スケッチ一覧のソート基準
enum SketchSortCriteria {
  /// 作成日時でソート
  createdAt,

  /// 更新日時でソート
  updatedAt,

  /// タイトルでソート
  title,
}

/// スケッチ一覧表示用のスケッチデータを管理するProvider
class SketchListController extends ChangeNotifier {
  final SketchStorage _storage;
  List<SketchMetadata> _sketches = [];
  bool _isLoading = false;
  String? _error;
  SketchSortCriteria _sortCriteria = SketchSortCriteria.updatedAt;
  bool _sortAscending = false;

  SketchListController(this._storage) {
    _loadSketches();
  }

  List<SketchMetadata> get sketches => _sketches;
  bool get isLoading => _isLoading;
  String? get error => _error;
  SketchSortCriteria get sortCriteria => _sortCriteria;
  bool get sortAscending => _sortAscending;

  /// スケッチ一覧を読み込む
  Future<void> _loadSketches() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sketches = await _storage.listSketches();
      _sortSketches();
    } catch (e) {
      _error = '一覧の読み込みに失敗しました: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// スケッチ一覧を更新する
  Future<void> refresh() => _loadSketches();

  /// ソート基準を変更する
  void setSortCriteria(SketchSortCriteria criteria) {
    if (_sortCriteria == criteria) {
      _sortAscending = !_sortAscending;
    } else {
      _sortCriteria = criteria;
      _sortAscending = false;
    }
    _sortSketches();
    notifyListeners();
  }

  /// スケッチをソートする
  void _sortSketches() {
    _sketches.sort((a, b) {
      int compare;
      switch (_sortCriteria) {
        case SketchSortCriteria.createdAt:
          compare = a.createdAt.compareTo(b.createdAt);
          break;
        case SketchSortCriteria.updatedAt:
          compare = a.updatedAt.compareTo(b.updatedAt);
          break;
        case SketchSortCriteria.title:
          compare = a.title.compareTo(b.title);
          break;
      }
      return _sortAscending ? compare : -compare;
    });
  }
}

/// スケッチ一覧のヘッダー（ソート機能付き）
class SketchListHeader extends StatelessWidget {
  final SketchListController controller;

  const SketchListHeader({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text(
            'スケッチ一覧',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          PopupMenuButton<SketchSortCriteria>(
            tooltip: 'ソート',
            icon: const Icon(Icons.sort),
            initialValue: controller.sortCriteria,
            onSelected: controller.setSortCriteria,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: SketchSortCriteria.updatedAt,
                child: Text('更新日時順'),
              ),
              const PopupMenuItem(
                value: SketchSortCriteria.createdAt,
                child: Text('作成日時順'),
              ),
              const PopupMenuItem(
                value: SketchSortCriteria.title,
                child: Text('タイトル順'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// スケッチ一覧を表示するウィジェット
class SketchList extends StatelessWidget {
  final SketchListController controller;
  final void Function(SketchMetadata) onSketchTap;
  final double spacing;
  final double thumbnailSize;

  const SketchList({
    super.key,
    required this.controller,
    required this.onSketchTap,
    this.spacing = 16,
    this.thumbnailSize = 150,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (controller.error != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  controller.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.refresh,
                  child: const Text('再読み込み'),
                ),
              ],
            ),
          );
        }

        if (controller.sketches.isEmpty) {
          return const Center(
            child: Text('スケッチがありません'),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SketchListHeader(controller: controller),
              ),
              SliverPadding(
                padding: EdgeInsets.all(spacing),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: thumbnailSize + spacing,
                    mainAxisSpacing: spacing,
                    crossAxisSpacing: spacing,
                    childAspectRatio: 1,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return SketchThumbnail(
                        metadata: controller.sketches[index],
                        size: thumbnailSize,
                        onTap: () => onSketchTap(controller.sketches[index]),
                      );
                    },
                    childCount: controller.sketches.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 保存・読み込み時のプログレス表示用のオーバーレイ
class ProgressOverlay extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback? onRetry;

  const ProgressOverlay({
    super.key,
    required this.message,
    this.isError = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isError) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                ],
                Text(
                  message,
                  style: TextStyle(
                    color: isError ? Theme.of(context).colorScheme.error : null,
                  ),
                ),
                if (isError && onRetry != null) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: onRetry,
                    child: const Text('再試行'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
