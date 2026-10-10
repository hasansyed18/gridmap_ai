// ignore_for_file: avoid_print
import '../models/cell_type.dart';
import '../models/models.dart';

class RoutingService {
  static List<CellPos>? findPath({
    required Map<String, CellType> cells,
    required CellPos start,
    required CellPos goal,
    bool wheelchair = false,
  }) {
    CellPos? snap(CellPos origin) {
      if (cells.containsKey(origin.key)) return origin;
      CellPos? best;
      var bestDist = 999999;
      for (var r = 1; r <= 5; r++) {
        for (var dx = -r; dx <= r; dx++) {
          for (var dy = -r; dy <= r; dy++) {
            if (dx.abs() > 5 || dy.abs() > 5) continue;
            final cand = CellPos(origin.x + dx, origin.y + dy);
            if (cells.containsKey(cand.key)) {
              final d = dx.abs() + dy.abs();
              if (d < bestDist) {
                bestDist = d;
                best = cand;
              }
            }
          }
        }
        if (best != null) return best;
      }
      return null;
    }

    final effectiveStart = snap(start);
    final effectiveGoal = snap(goal);

    if (effectiveStart == null || effectiveGoal == null) {
      print('A* from ${start.key} to ${goal.key}');
      print('Start cell: ${cells[start.key]}, Goal cell: ${cells[goal.key]}');
      print('Path length: null');
      return null;
    }

    bool isWalkable(CellType t) =>
        t == CellType.room ||
        t == CellType.corridor ||
        t == CellType.entrance ||
        t == CellType.exit ||
        t == CellType.walkable ||
        t == CellType.landmark ||
        t == CellType.washroom ||
        t == CellType.ramp ||
        t == CellType.lift;

    bool isCrossable(int x, int y) {
      final t = cells['$x,$y'];
      if (t == null) return false;
      if (t == CellType.stairs && wheelchair) return false;
      return true;
    }

    if (!isCrossable(effectiveStart.x, effectiveStart.y) ||
        !isCrossable(effectiveGoal.x, effectiveGoal.y)) {
      print('A* from ${start.key} to ${goal.key}');
      print('Start cell: ${cells[start.key]}, Goal cell: ${cells[goal.key]}');
      print('Path length: null');
      return null;
    }

    int cost(int x, int y) {
      final t = cells['$x,$y'];
      if (t == null) return 999;
      if (t == CellType.stairs) {
        return wheelchair ? 999999 : 1;
      }
      if (isWalkable(t)) return 1;
      if (t == CellType.blocked) return 50;
      return 50;
    }

    int heuristic(CellPos a) =>
        (a.x - effectiveGoal.x).abs() + (a.y - effectiveGoal.y).abs();

    final open = _PQ();
    final gScore = <String, int>{effectiveStart.key: 0};
    final cameFrom = <String, CellPos>{};
    open.add(effectiveStart, heuristic(effectiveStart));

    const dirs = [
      [0, 1],
      [0, -1],
      [1, 0],
      [-1, 0],
    ];

    final closed = <String>{};
    const maxIter = 20000;
    var iter = 0;
    List<CellPos>? path;

    while (open.isNotEmpty && iter < maxIter) {
      iter++;
      final current = open.removeFirst();
      if (closed.contains(current.key)) continue;
      closed.add(current.key);

      if (current == effectiveGoal) {
        final reconstructed = <CellPos>[current];
        var node = current;
        while (cameFrom.containsKey(node.key)) {
          node = cameFrom[node.key]!;
          reconstructed.add(node);
        }
        path = reconstructed.reversed.toList();
        break;
      }

      final currentG = gScore[current.key] ?? 1 << 30;
      for (final d in dirs) {
        final nx = current.x + d[0];
        final ny = current.y + d[1];
        if (!isCrossable(nx, ny)) continue;
        final neighbor = CellPos(nx, ny);
        final tentativeG = currentG + cost(nx, ny);
        if (tentativeG < (gScore[neighbor.key] ?? 1 << 30)) {
          gScore[neighbor.key] = tentativeG;
          cameFrom[neighbor.key] = current;
          open.add(neighbor, tentativeG + heuristic(neighbor));
        }
      }
    }

    print('A* from ${start.key} to ${goal.key}');
    print('Start cell: ${cells[start.key]}, Goal cell: ${cells[goal.key]}');
    print('Path length: ${path?.length}');

    return path;
  }
}

class _PQ {
  final List<CellPos> _items = [];
  final List<int> _priority = [];

  bool get isNotEmpty => _items.isNotEmpty;

  void add(CellPos item, int priority) {
    _items.add(item);
    _priority.add(priority);
    _bubbleUp(_items.length - 1);
  }

  CellPos removeFirst() {
    final top = _items.first;
    final lastItem = _items.removeLast();
    final lastPrio = _priority.removeLast();
    if (_items.isNotEmpty) {
      _items[0] = lastItem;
      _priority[0] = lastPrio;
      _bubbleDown(0);
    }
    return top;
  }

  void _bubbleUp(int i) {
    while (i > 0) {
      final p = (i - 1) ~/ 2;
      if (_priority[i] < _priority[p]) {
        _swap(i, p);
        i = p;
      } else {
        break;
      }
    }
  }

  void _bubbleDown(int i) {
    final n = _items.length;
    while (true) {
      var smallest = i;
      final l = 2 * i + 1;
      final r = 2 * i + 2;
      if (l < n && _priority[l] < _priority[smallest]) smallest = l;
      if (r < n && _priority[r] < _priority[smallest]) smallest = r;
      if (smallest == i) break;
      _swap(i, smallest);
      i = smallest;
    }
  }

  void _swap(int a, int b) {
    final ti = _items[a];
    _items[a] = _items[b];
    _items[b] = ti;
    final tp = _priority[a];
    _priority[a] = _priority[b];
    _priority[b] = tp;
  }
}