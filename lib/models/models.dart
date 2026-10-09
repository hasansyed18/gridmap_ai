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
  final String icon;
  const Landmark({
    required this.id,
    required this.name,
    required this.position,
    this.icon = 'place',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'x': position.x,
        'y': position.y,
        'icon': icon,
      };
}

class Room {
  final String id;
  final String name;
  final List<String> aliases;
  final List<CellPos> cells;
  final bool isAccessible;
  final String? description;

  const Room({
    required this.id,
    required this.name,
    this.aliases = const [],
    required this.cells,
    this.isAccessible = true,
    this.description,
  });

  Room copyWith({
    String? name,
    List<String>? aliases,
    List<CellPos>? cells,
    bool? isAccessible,
    String? description,
  }) {
    return Room(
      id: id,
      name: name ?? this.name,
      aliases: aliases ?? this.aliases,
      cells: cells ?? this.cells,
      isAccessible: isAccessible ?? this.isAccessible,
      description: description ?? this.description,
    );
  }

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
  final int width;
  final int height;
  final double squareFeet;
  List<List<CellType>> cells;
  final List<Room> rooms;
  final List<Landmark> landmarks;

  Floor({
    required this.id,
    required this.name,
    required this.level,
    required this.width,
    required this.height,
    required this.squareFeet,
    List<List<CellType>>? cells,
    List<Room>? rooms,
    List<Landmark>? landmarks,
  })  : cells = cells ?? List.generate(height, (_) => List.filled(width, CellType.empty)),
        rooms = rooms ?? [],
        landmarks = landmarks ?? [];

  CellType cellAt(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return CellType.blocked;
    return cells[y][x];
  }

  void setCell(int x, int y, CellType type) {
    if (x < 0 || x >= width || y < 0 || y >= height) return;
    cells[y][x] = type;
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
  final double squareFeet;
  final List<Floor> floors;

  Building({
    required this.id,
    required this.name,
    required this.squareFeet,
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