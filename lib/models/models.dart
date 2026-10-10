import 'cell_type.dart';

class CellPos {
  final int x;
  final int y;
  const CellPos(this.x, this.y);

  String get key => '$x,$y';
  static CellPos fromKey(String k) {
    final parts = k.split(',');
    return CellPos(int.parse(parts[0]), int.parse(parts[1]));
  }

  @override
  bool operator ==(Object other) =>
      other is CellPos && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

class Landmark {
  final String id;
  final String name;
  final CellPos position;
  const Landmark({
    required this.id,
    required this.name,
    required this.position,
  });
}

class Room {
  final String id;
  final String name;
  final List<String> aliases;
  final List<CellPos> cells;
  final bool isAccessible;

  const Room({
    required this.id,
    required this.name,
    this.aliases = const [],
    required this.cells,
    this.isAccessible = true,
  });

  Map<String, dynamic> toMap(String floorId) => {
        'id': id,
        'floor_id': floorId,
        'name': name,
        'aliases': aliases,
        'is_accessible': isAccessible,
      };
}

class Floor {
  final String id;
  String name;
  final int level;
  // Sparse storage — only painted cells exist
  final Map<String, CellType> cells;
  final List<Room> rooms;
  final List<Landmark> landmarks;

  Floor({
    required this.id,
    required this.name,
    required this.level,
    Map<String, CellType>? cells,
    List<Room>? rooms,
    List<Landmark>? landmarks,
  })  : cells = cells ?? {},
        rooms = rooms ?? [],
        landmarks = landmarks ?? [];

  CellType cellAt(int x, int y) => cells['$x,$y'] ?? CellType.empty;

  void setCell(int x, int y, CellType type) {
    final key = '$x,$y';
    if (type == CellType.empty) {
      cells.remove(key);
    } else {
      cells[key] = type;
    }
  }

  Room? roomAt(int x, int y) {
    for (final r in rooms) {
      for (final c in r.cells) {
        if (c.x == x && c.y == y) return r;
      }
    }
    return null;
  }

  Landmark? landmarkAt(int x, int y) {
    for (final l in landmarks) {
      if (l.position.x == x && l.position.y == y) return l;
    }
    return null;
  }
}

class Building {
  final String id;
  String name;
  final List<Floor> floors;

  Building({
    required this.id,
    required this.name,
    List<Floor>? floors,
  }) : floors = floors ?? [];

  int get floorCount => floors.length;
}

class Organization {
  final String id;
  String name;
  String description;
  String category;
  double? lat;
  double? lng;
  final List<Building> buildings;

  Organization({
    required this.id,
    required this.name,
    this.description = '',
    this.category = 'college',
    this.lat,
    this.lng,
    List<Building>? buildings,
  }) : buildings = buildings ?? [];
}