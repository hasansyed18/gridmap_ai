import '../models/cell_type.dart';
import '../models/models.dart';

class SearchService {
  static List<Room> searchRooms(List<Room> rooms, String query) {
    final q = _norm(query);
    if (q.isEmpty) return [];

    final scored = <MapEntry<Room, int>>[];
    for (final r in rooms) {
      var score = 0;
      final name = _norm(r.name);

      if (name == q) {
        score = 100;
      } else if (name.startsWith(q)) {
        score = 80;
      } else if (name.contains(q)) {
        score = 60;
      } else {
        for (final alias in r.aliases) {
          final a = _norm(alias);
          if (a == q) {
            score = 95;
            break;
          }
          if (a.startsWith(q)) {
            score = 75;
            break;
          }
          if (a.contains(q)) {
            score = 55;
            break;
          }
        }
      }

      // Common abbreviation match (CSE → Computer Science & Engineering)
      if (score == 0 && _matchesInitials(r.name, q)) score = 70;

      if (score > 0) scored.add(MapEntry(r, score));
    }

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).toList();
  }

  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static bool _matchesInitials(String name, String q) {
    final words = _norm(name).split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return false;
    final initials = words.map((w) => w[0]).join();
    return initials == q;
  }

  /// Midpoint of a room's cells — sensible route start/goal.
  static CellPos? representativePoint(Room room) {
    if (room.cells.isEmpty) return null;
    return room.cells[room.cells.length ~/ 2];
  }

  /// Nearest walkable cell if the target isn't walkable.
  static CellPos? nearestWalkable({
    required Map<String, CellType> cells,
    required CellPos target,
    int maxRadius = 5,
  }) {
    final t = cells[target.key];
    if (t != null && t.isWalkable) return target;

    for (var r = 1; r <= maxRadius; r++) {
      for (var dx = -r; dx <= r; dx++) {
        for (var dy = -r; dy <= r; dy++) {
          if (dx.abs() != r && dy.abs() != r) continue;
          final pos = CellPos(target.x + dx, target.y + dy);
          final t2 = cells[pos.key];
          if (t2 != null && t2.isWalkable) return pos;
        }
      }
    }
    return null;
  }
}