import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../models/cell_type.dart';

const _uuid = Uuid();

enum PlacementMode { custom, quick }

class AppState extends ChangeNotifier {
  Organization? organization;
  int currentFloorIndex = 0;
  CellType activeTool = CellType.room;

  // Placement
  PlacementMode placementMode = PlacementMode.quick;
  int quickWidth = 3;
  int quickHeight = 3;
  CellType quickType = CellType.room;

  // Entrance pick (room id waiting for entrance)
  String? pendingEntranceRoomId;

  Floor? get currentFloor {
    final org = organization;
    if (org == null || org.buildings.isEmpty) return null;
    final b = org.buildings.first;
    if (b.floors.isEmpty) return null;
    if (currentFloorIndex >= b.floors.length) currentFloorIndex = 0;
    return b.floors[currentFloorIndex];
  }

  Building? get currentBuilding {
    final org = organization;
    if (org == null || org.buildings.isEmpty) return null;
    return org.buildings.first;
  }

  bool get hasOrganization => organization != null;
  bool get hasMap => currentFloor != null;
  bool get isPickingEntrance => pendingEntranceRoomId != null;

  // ---------- Hydrate from Supabase ----------
  /// Replaces in-memory state with a loaded organization.
  /// Pass the floor index you want active (default 0).
  void hydrate({
    required Organization org,
    int floorIndex = 0,
  }) {
    organization = org;
    currentFloorIndex = floorIndex;
    pendingEntranceRoomId = null;
    placementMode = PlacementMode.quick;
    notifyListeners();
  }

  // ---------- Org ----------
  void createOrganization({
    required String name,
    required String description,
    required String category,
    double? lat,
    double? lng,
  }) {
    organization = Organization(
      id: _uuid.v4(),
      name: name,
      description: description,
      category: category,
      lat: lat,
      lng: lng,
    );
    notifyListeners();
  }

  void createBuilding({required String buildingName}) {
    if (organization == null) return;
    final building = Building(
      id: _uuid.v4(),
      name: buildingName,
      floors: [Floor(id: _uuid.v4(), name: 'Ground Floor', level: 0)],
    );
    organization!.buildings.add(building);
    currentFloorIndex = 0;
    notifyListeners();
  }

  void addFloor() {
    final b = currentBuilding;
    if (b == null) return;
    b.floors.add(Floor(
      id: _uuid.v4(),
      name: 'Floor ${b.floors.length}',
      level: b.floors.length,
    ));
    notifyListeners();
  }

  void switchFloor(int index) {
    final b = currentBuilding;
    if (b == null || index < 0 || index >= b.floors.length) return;
    currentFloorIndex = index;
    notifyListeners();
  }

  // ---------- Placement mode ----------
  void setPlacementMode(PlacementMode m) {
    placementMode = m;
    notifyListeners();
  }

  void setQuickSize(int w, int h) {
    quickWidth = w.clamp(1, 20);
    quickHeight = h.clamp(1, 20);
    notifyListeners();
  }

  void setQuickType(CellType t) {
    quickType = t;
    notifyListeners();
  }

  void setActiveTool(CellType t) {
    activeTool = t;
    notifyListeners();
  }

  // ---------- Cell ops ----------
  void setCell(int x, int y, CellType type) {
    final floor = currentFloor;
    if (floor == null) return;
    floor.setCell(x, y, type);
    notifyListeners();
  }

  void clearFloor() {
    final floor = currentFloor;
    if (floor == null) return;
    floor.cells.clear();
    floor.rooms.clear();
    floor.landmarks.clear();
    notifyListeners();
  }

  // ---------- Quick place ----------
  String? placeQuickBlock(CellPos topLeft) {
    final floor = currentFloor;
    if (floor == null) return null;

    final cells = <CellPos>[];
    for (var dy = 0; dy < quickHeight; dy++) {
      for (var dx = 0; dx < quickWidth; dx++) {
        cells.add(CellPos(topLeft.x + dx, topLeft.y + dy));
      }
    }

    if (quickType == CellType.room) {
      final room = Room(
        id: _uuid.v4(),
        name: 'Room ${floor.rooms.length + 1}',
        cells: cells,
      );
      floor.rooms.add(room);
      for (final c in cells) {
        floor.setCell(c.x, c.y, CellType.room);
      }
      notifyListeners();
      return room.id;
    }

    for (final c in cells) {
      floor.setCell(c.x, c.y, quickType);
    }
    notifyListeners();
    return null;
  }

  void renameRoom(String roomId, String newName) {
    final floor = currentFloor;
    if (floor == null) return;
    final idx = floor.rooms.indexWhere((r) => r.id == roomId);
    if (idx == -1) return;
    final r = floor.rooms[idx];
    floor.rooms[idx] = Room(
      id: r.id,
      name: newName,
      aliases: r.aliases,
      cells: r.cells,
    );
    notifyListeners();
  }

  // ---------- Custom place ----------
  void placeCustomBlock(List<CellPos> cells, CellType type, {String? name}) {
    final floor = currentFloor;
    if (floor == null) return;

    if (type == CellType.room) {
      final room = Room(
        id: _uuid.v4(),
        name: name ?? 'Room ${floor.rooms.length + 1}',
        cells: cells,
      );
      floor.rooms.add(room);
      for (final c in cells) {
        floor.setCell(c.x, c.y, CellType.room);
      }
    } else if (type == CellType.empty) {
      for (final c in cells) {
        floor.setCell(c.x, c.y, CellType.empty);
      }
    } else {
      for (final c in cells) {
        floor.setCell(c.x, c.y, type);
      }
    }
    notifyListeners();
  }

  // ---------- Entrance flow ----------
  void startEntrancePick(String roomId) {
    pendingEntranceRoomId = roomId;
    notifyListeners();
  }

  void cancelEntrancePick() {
    pendingEntranceRoomId = null;
    notifyListeners();
  }

  bool applyEntranceAndWalls(CellPos entranceCell) {
    final roomId = pendingEntranceRoomId;
    if (roomId == null) return false;
    final floor = currentFloor;
    if (floor == null) return false;

    final roomIdx = floor.rooms.indexWhere((r) => r.id == roomId);
    if (roomIdx == -1) return false;
    final room = floor.rooms[roomIdx];
    final roomKeys = room.cells.map((c) => c.key).toSet();

    final perimeter = <String, CellPos>{};
    for (final rc in room.cells) {
      final neighbors = [
        CellPos(rc.x + 1, rc.y),
        CellPos(rc.x - 1, rc.y),
        CellPos(rc.x, rc.y + 1),
        CellPos(rc.x, rc.y - 1),
      ];
      for (final n in neighbors) {
        if (!roomKeys.contains(n.key)) perimeter[n.key] = n;
      }
    }

    if (!perimeter.containsKey(entranceCell.key)) return false;

    floor.setCell(entranceCell.x, entranceCell.y, CellType.entrance);

    for (final p in perimeter.values) {
      if (p.key == entranceCell.key) continue;
      final existing = floor.cellAt(p.x, p.y);
      if (existing == CellType.empty || existing == CellType.blocked) {
        floor.setCell(p.x, p.y, CellType.blocked);
      }
    }

    pendingEntranceRoomId = null;
    notifyListeners();
    return true;
  }

  List<CellPos> roomPerimeter(Room room) {
    final roomKeys = room.cells.map((c) => c.key).toSet();
    final perimeter = <String, CellPos>{};
    for (final rc in room.cells) {
      final neighbors = [
        CellPos(rc.x + 1, rc.y),
        CellPos(rc.x - 1, rc.y),
        CellPos(rc.x, rc.y + 1),
        CellPos(rc.x, rc.y - 1),
      ];
      for (final n in neighbors) {
        if (!roomKeys.contains(n.key)) perimeter[n.key] = n;
      }
    }
    return perimeter.values.toList();
  }

  Room? roomById(String id) {
    final floor = currentFloor;
    if (floor == null) return null;
    final idx = floor.rooms.indexWhere((r) => r.id == id);
    return idx == -1 ? null : floor.rooms[idx];
  }

  void addLandmark(String name, CellPos position,
      {CellType type = CellType.landmark}) {
    final floor = currentFloor;
    if (floor == null) return;
    floor.landmarks.add(Landmark(
      id: _uuid.v4(),
      name: name,
      position: position,
    ));
    floor.setCell(position.x, position.y, type);
    notifyListeners();
  }

  void reset() {
    organization = null;
    currentFloorIndex = 0;
    activeTool = CellType.room;
    quickType = CellType.room;
    quickWidth = 3;
    quickHeight = 3;
    placementMode = PlacementMode.quick;
    pendingEntranceRoomId = null;
    notifyListeners();
  }
}