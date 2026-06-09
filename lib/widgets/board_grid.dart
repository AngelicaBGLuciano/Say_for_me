import 'package:flutter/material.dart';
import '../models/board_item.dart';
import '../models/category_model.dart';
import '../models/pictogram_model.dart';
import 'category_item.dart';
import 'pictogram_item.dart';

class BoardGrid extends StatelessWidget {
  final bool isLoading;
  final bool isEditMode;
  final List<BoardItem> items;
  final Set<String> activeIdentifiers;
  final Function(BoardItem) onItemTap;
  final Function(List<BoardItem>) onItemsChanged;
  final VoidCallback onScrollDetected;

  const BoardGrid({
    super.key,
    required this.isLoading,
    required this.isEditMode,
    required this.items,
    required this.activeIdentifiers,
    required this.onItemTap,
    required this.onItemsChanged,
    required this.onScrollDetected,
  });

  static const double cardWidth = 120;
  static const double cardHeight = 95;

  static const List<String> typeOrder = [
    'Categorias',
    'pessoas',
    'verbos',
    'substantivos',
    'descritivo',
    'social',
    'diversos',
  ];

  static const Map<String, int> columnsPerType = {
    'Categorias': 1,
    'pessoas': 1,
    'verbos': 3,
    'substantivos': 3,
    'descritivo': 1,
    'social': 1,
    'diversos': 1,
  };

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final groupedItems = _groupItemsByType();

    final bool isInsideCategory = items.any((item) => item is BackItem);

    if (isInsideCategory && !isEditMode) {
      return Expanded(
        child: GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.05,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return SizedBox(
              height: 125,
              child: _buildItem(items[index]),
            );
          },
        ),
      );
    }

    final visualColumns = _buildVisualColumns(groupedItems);

    return Expanded(
  child: NotificationListener<ScrollNotification>(
    onNotification: (notification) {
      if (notification is ScrollEndNotification) {
        onScrollDetected();
      }
      return false;
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: visualColumns.map((columnData) {
            return SizedBox(
              width: cardWidth,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _buildColumn(columnData, visualColumns),
              ),
            );
          }).toList(),
        ),
      ),
    ),
  );
  }

  Map<String, List<BoardItem>> _groupItemsByType() {
    final Map<String, List<BoardItem>> grouped = {
      for (final type in typeOrder) type: [],
    };

    for (final item in items) {
      if (item is BackItem) {
        grouped['Categorias']!.insert(0, item);
      } else if (item is Category) {
        grouped['Categorias']!.add(item);
      } else if (item is Pictogram) {
        final type = typeOrder.contains(item.type) ? item.type : 'diversos';
        grouped[type]!.add(item);
      }
    }

    return grouped;
  }

  List<_VisualColumn> _buildVisualColumns(
    Map<String, List<BoardItem>> groupedItems,
  ) {
    final List<_VisualColumn> columns = [];

    for (final type in typeOrder) {
      final typeItems = groupedItems[type] ?? [];
      final columnCount = columnsPerType[type] ?? 1;

      final split = _splitInterleaved(typeItems, columnCount);

      for (int i = 0; i < columnCount; i++) {
        columns.add(
          _VisualColumn(
            type: type,
            columnIndex: i,
            items: split[i],
          ),
        );
      }
    }

    return columns;
  }

  List<List<BoardItem>> _splitInterleaved(
    List<BoardItem> source,
    int columnCount,
  ) {
    final result = List.generate(columnCount, (_) => <BoardItem>[]);

    for (int i = 0; i < source.length; i++) {
      result[i % columnCount].add(source[i]);
    }

    return result;
  }

  Widget _buildColumn(
    _VisualColumn columnData,
    List<_VisualColumn> allColumns,
  ) {
    return DragTarget<_DraggedItem>(
      onWillAcceptWithDetails: (details) {
        return isEditMode && details.data.type == columnData.type;
      },
      onAcceptWithDetails: (details) {
        _moveItem(
          dragged: details.data,
          targetColumn: columnData,
          targetIndex: columnData.items.length,
          allColumns: allColumns,
        );
      },
      builder: (context, candidateData, rejectedData) {
        return Column(
          children: [
            for (int index = 0; index < columnData.items.length; index++)
              _buildDraggableItem(
                item: columnData.items[index],
                index: index,
                columnData: columnData,
                allColumns: allColumns,
              ),
          ],
        );
      },
    );
  }

  Widget _buildDraggableItem({
    required BoardItem item,
    required int index,
    required _VisualColumn columnData,
    required List<_VisualColumn> allColumns,
  }) {
    final child = SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: _buildItem(item),
    );

    if (!isEditMode) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: child,
      );
    }

    return DragTarget<_DraggedItem>(
      onWillAcceptWithDetails: (details) {
        return details.data.type == columnData.type;
      },
      onAcceptWithDetails: (details) {
        _moveItem(
          dragged: details.data,
          targetColumn: columnData,
          targetIndex: index,
          allColumns: allColumns,
        );
      },
      builder: (context, candidateData, rejectedData) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: LongPressDraggable<_DraggedItem>(
            data: _DraggedItem(
              type: columnData.type,
              columnIndex: columnData.columnIndex,
              item: item,
            ),
            feedback: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: _buildItem(item),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.25,
              child: child,
            ),
            child: child,
          ),
        );
      },
    );
  }

  void _moveItem({
    required _DraggedItem dragged,
    required _VisualColumn targetColumn,
    required int targetIndex,
    required List<_VisualColumn> allColumns,
  }) {
    final updatedColumns = allColumns.map((column) {
      return _VisualColumn(
        type: column.type,
        columnIndex: column.columnIndex,
        items: List<BoardItem>.from(column.items),
      );
    }).toList();

    final sourceColumn = updatedColumns.firstWhere(
      (column) =>
          column.type == dragged.type &&
          column.columnIndex == dragged.columnIndex,
    );

    final destinationColumn = updatedColumns.firstWhere(
      (column) =>
          column.type == targetColumn.type &&
          column.columnIndex == targetColumn.columnIndex,
    );

    sourceColumn.items.removeWhere(
      (item) => _getIdentifier(item) == _getIdentifier(dragged.item),
    );

    final alreadyExists = destinationColumn.items.any(
      (item) => _getIdentifier(item) == _getIdentifier(dragged.item),
    );

    if (!alreadyExists) {
      final safeIndex = targetIndex.clamp(0, destinationColumn.items.length);
      destinationColumn.items.insert(safeIndex, dragged.item);
    }

    final List<BoardItem> newItems = [];

    for (final type in typeOrder) {
      final typeColumns = updatedColumns
          .where((column) => column.type == type)
          .toList()
        ..sort((a, b) => a.columnIndex.compareTo(b.columnIndex));

      newItems.addAll(_flattenInterleaved(typeColumns));
    }

    onItemsChanged(newItems);
  }

  List<BoardItem> _flattenInterleaved(List<_VisualColumn> columns) {
    final List<BoardItem> result = [];
    final maxLength = columns
        .map((column) => column.items.length)
        .fold<int>(0, (previous, current) => current > previous ? current : previous);

    for (int row = 0; row < maxLength; row++) {
      for (final column in columns) {
        if (row < column.items.length) {
          result.add(column.items[row]);
        }
      }
    }

    return result;
  }

  Widget _buildItem(BoardItem item) {
    if (item is BackItem) {
      return GestureDetector(
        onTap: () => onItemTap(item),
        child: Card(
          color: Colors.grey.shade300,
          child: const Center(
            child: Icon(Icons.arrow_back, size: 36),
          ),
        ),
      );
    }

    String identifier = '';
    Widget child;

    if (item is Pictogram) {
      identifier = item.keyword;
      child = PictogramItem(
        pictogram: item,
        onTap: () => onItemTap(item),
      );
    } else if (item is Category) {
      identifier = 'cat:${item.name}';
      child = CategoryItem(
        category: item,
        onTap: () => onItemTap(item),
      );
    } else {
      return const SizedBox.shrink();
    }

    final isActive = activeIdentifiers.contains(identifier);

    return Opacity(
      opacity: isEditMode && !isActive ? 0.4 : 1.0,
      child: child,
    );
  }

  String _getIdentifier(BoardItem item) {
    if (item is Pictogram) return item.keyword;
    if (item is Category) return 'cat:${item.name}';
    if (item is BackItem) return 'back-item';
    return item.hashCode.toString();
  }
}

class _VisualColumn {
  final String type;
  final int columnIndex;
  final List<BoardItem> items;

  _VisualColumn({
    required this.type,
    required this.columnIndex,
    required this.items,
  });
}

class _DraggedItem {
  final String type;
  final int columnIndex;
  final BoardItem item;

  _DraggedItem({
    required this.type,
    required this.columnIndex,
    required this.item,
  });
}