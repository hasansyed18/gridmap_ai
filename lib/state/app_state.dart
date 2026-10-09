import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../models/cell_type.dart';

const _uuid = Uuid();

class AppState extends ChangeNotifier {
  // Session
  Organization? organization;
  int currentFloorIndex = 0;

  // Editor
  CellType activeTool = CellType.room;
  final Set<String> _selection = {};
  bool isSelecting = false;

  // Visitor
  String? visitorStartLandmarkId;
  String? visitorDestinationRoomId;
  bool wheelchairMode = false;
  List<CellPos>? currentRoute;

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

  Set<String> get selection => _selection;

  // --- Org setup ---
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

  // --- Building + floor ---
  void createBuildingWithFloor({
    required String buildingName,
    required double squareFeet,
    required int gridWidth,
    required int gridHeight,
  }) {
    if (organization == null) return;
    final building = Building(
      id: _uuid.v4(),
      name: buildingName,
      squareFeet: squareFeet,
      floors: [
        Floor(
          id: _uuid.v4(),
          name: 'Ground Floor',
          level: 0,
          width: gridWidth,
          height: gridHeight,
          squareFeet: squareFeet,
        ),
      ],
    );
    organization!.buildings.add(building);
    currentFloorIndex = 0;
    notifyListeners();
  }

  void addFloor() {
    final building = currentBuilding;
    if (building == null) return;
    final lastFloor = building.floors.last;
    building.floors.add(Floor(
      id: _uuid.v4(),
      name: 'Floor ${building.floors.length}',
      level: building.floors.length,
      width: lastFloor.width,
      height: lastFloor.height,
      squareFeet: lastFloor.squareFeet,
    ));
    notifyListeners();
  }

  void switchFloor(int index) {
    final building = currentBuilding;
    if (building == null) return;
    if (index < 0 || index >= building.floors.length) return;
    currentFloorIndex = index;
    _selection.clear();
    notifyListeners();
  }

  // --- Editor ---
  void setActiveTool(CellType tool) {
    activeTool = tool;
    notifyListeners();
  }

  void setCell(int x, int y, CellType type) {
    final floor = currentFloor;
    if (floor == null) return;
    floor.setCell(x, y, type);
    notifyListeners();
  }

  void batchSetSelection(CellType type) {
    final floor = currentFloor;
    if (floor == null) return;
    for (final k in _selection) {
      final p = CellPos.fromKey(k);
      floor.setCell(p.x, p.y, type);
    }
    notifyListeners();
  }

  void toggleSelection(CellPos p) {
    if (_selection.contains(p.key)) {
      _selection.remove(p.key);
    } else {
      _selection.add(p.key);
    }
    notifyListeners();
  }

  void setSelection(List<CellPos> cells) {
    _selection
      ..clear()
      ..addAll(cells.map((c) => c.key));
    notifyListeners();
  }

  void clearSelection() {
    _selection.clear();
    notifyListeners();
  }

  void addRoomFromSelection(String name, {List<String> aliases = const []}) {
    final floor = currentFloor;
    if (floor == null || _selection.isEmpty) return;
    final cells = _selection.map((k) => CellPos.fromKey(k)).toList();
    final room = Room(
      id: _uuid.v4(),
      name: name,
      aliases: aliases,
      cells: cells,
    );
    floor.rooms.add(room);
    for (final c in cells) {
      floor.setCell(c.x, c.y, CellType.room);
    }
    _selection.clear();
    notifyListeners();
  }

  void addLandmark(String name, CellPos position) {
    final floor = currentFloor;
    if (floor == null) return;
    floor.landmarks.add(Landmark(
      id: _uuid.v4(),
      name: name,
      position: position,
    ));
    floor.setCell(position.x, position.y, CellType.landmark);
    notifyListeners();
  }

  void deleteRoom(String roomId) {
    final floor = currentFloor;
    if (floor == null) return;
    floor.rooms.removeWhere((r) => r.id == roomId);
    notifyListeners();
  }

  // --- Visitor ---
  void setWheelchairMode(bool value) {
    wheelchairMode = value;
    notifyListeners();
  }

  void setRoute(List<CellPos>? route) {
    currentRoute = route;
    notifyListeners();
  }

  void reset() {
    organization = null;
    currentFloorIndex = 0;
    activeTool = CellType.room;
    _selection.clear();
    wheelchairMode = false;
    currentRoute = null;
    notifyListeners();
  }
}